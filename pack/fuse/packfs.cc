/* TODO: 
 *       306 lines is one hundred or so too many
 *       Real dependencies
 *       Don't break fuse cmdline
 */

#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <fuse.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <vector>

typedef char *cstr;

struct packfs_file {
  char *path;
  int fh;
  off_t  ofs;
  size_t size;
  packfs_file *shadowed_by;

  int xread(char *buf, size_t req_size, off_t req_ofs) {
    if(req_ofs >= size) return 0;
    if(req_size > size - req_ofs) req_size = size - req_ofs;
    if(-1 == lseek(fh, ofs+req_ofs, SEEK_SET)) return -EIO;
    return read(fh, buf, req_size);
  }  

  int getattr(struct stat *stbuf) {
    struct stat stbuf_archive;
    if(0 != fstat(fh, &stbuf_archive)) return -EIO;
    stbuf->st_mode  = S_IFREG | 0444;
    stbuf->st_nlink = 1;
    stbuf->st_size  = size;
    stbuf->st_ctime = stbuf_archive.st_ctime;
    stbuf->st_mtime = stbuf_archive.st_mtime;
    stbuf->st_atime = stbuf_archive.st_atime;
    return 0;
  }
  
  packfs_file(char *_path, int _fh, off_t _ofs, size_t _size) {
    path = _path;
    fh = _fh;
    ofs = _ofs;
    size = _size;
    shadowed_by = NULL;
  }
};

struct pack_archive {
  const char *path;
  int fh;
  uint32_t pack_type;
  std::vector<char *> dep_names;
  std::vector<packfs_file *> files;  
  
  pack_archive(const char *_path) : path(_path) {
    fh = force_open(path);
    load_header();
    load_deps();
    load_files();
  }

private:

  uint32_t deps_size, deps_count;
  uint32_t files_size, files_count;
  int version;

  void load_header() {
    uint32_t header[6];
    uint32_t header_extra[2];
    force_read((char*)header, 24);
   
    if(header[0] == *(uint32_t*)("PFH0")) {
      version = 0;
    } else if(header[0] == *(uint32_t*)("PFH2")) {
      version = 2;
      force_read((char*)header_extra, 8);
    } else {
      fprintf(stderr, "Pack header error for %s\n", path);
      exit(1);
    }
    pack_type   = header[1];
    deps_count  = header[2];
    deps_size   = header[3];
    files_count = header[4];
    files_size  = header[5];
  }
  
  void load_deps() {
    char *deps_header_data = new char[deps_size];
    force_read(deps_header_data, deps_size);
    
    for(uint i=0,j=0; i<deps_count; i++) {
      dep_names.push_back(strdup(deps_header_data+j));
      j += strlen(dep_names[i]) + 1;
    }
    delete[] deps_header_data;
  }
  
  void load_files() {
    char *files_header_data = new char[files_size];
    force_read(files_header_data, files_size);

    off_t ofs = (version == 0 ? 24 : 32) + deps_size + files_size;
    for(uint i=0, j=0; i<files_count; i++) {
      int f_sz       = *(uint32_t*)(files_header_data+j);
      int f_path_len = strlen(files_header_data+j+4);

      char *f_path     = (char*)malloc(f_path_len+2);
      f_path[0] = '/';
      strcpy(f_path+1, files_header_data+j+4);
      adjust_slashes(f_path);

      files.push_back(new packfs_file(f_path, fh, ofs, f_sz));

      ofs += f_sz;
      j += f_path_len + 5;
    }
    delete[] files_header_data;
  }
  
  void adjust_slashes(char *path) {
    for(int i=0,len=strlen(path); i<len; i++)
      if(path[i] == '\\')
        path[i] = '/';
  }

  int force_open(const char *path) {
    int _fh = open(path, O_RDONLY);
    if(_fh == -1) {
      fprintf(stderr, "Error opening %s: %s\n", path, strerror(errno));
      exit(1);
    }
    return _fh;
  }
  
  void force_read(char *buf, int sz) {
    if(sz == 0) return;
    int ok = read(fh, buf, sz);
    if(ok != sz) {
      fprintf(stderr, "Error reading %s: Wanted to read %d bytes but got %d: %s\n", path, sz, ok, strerror(errno));
      exit(1);
    }
  }
};

/* STL hash_map is fail design, C/C++ has no GC, so dictionary needs to manage key's memory */
template <class T> class bucket {
public:
  std::vector<uint32_t> hashes;
  std::vector<char *> keys;
  std::vector<T *> values;

  T* get(uint32_t h, const char *key) {
    for(uint i=0; i<keys.size(); i++)
      if(h == hashes[i] && 0 == strcmp(keys[i], key))
        return values[i];
    return NULL;
  };
  
  void set(uint32_t h, const char *_key, T *value) {
    char *key = strdup(_key);

    for(uint i=0; i<keys.size(); i++)
      if(h == hashes[i] && 0 == strcmp(keys[i], key)) {
        free(keys[i]);
        keys[i] = key;
        values[i] = value;
        return;
      }

    hashes.push_back(h);
    keys.push_back(key);
    values.push_back(value);
  }
};

template <class T> class dictionary {
  bucket<T> buckets[256];

  uint32_t hash(const char*key) {
    uint32_t h = 0x84222325;
    while(*key) {
      h *= 0x1B3;
      h ^= (unsigned char)key[0];
      key++;
    }
    return h;
  }
public:
  T* operator [](const char *key) {
    uint32_t h = hash(key);
    return buckets[h&0xFF].get(h, key);
  };
  void set(const char *key, T *value) {
    uint32_t h = hash(key);
    buckets[h&0xFF].set(h, key, value);
  };
};

class packfs {
public:
  std::vector<pack_archive*> packs;
  dictionary<packfs_file > files;
  dictionary<std::vector<char*> > dirs;
  
  void add_file(packfs_file *file){
    if(files[file->path]) {
      files[file->path]->shadowed_by = file;
      files.set(file->path, file);
    } else {
      files.set(file->path, file);
      add_path(strdup(file->path));
    }
  }
  
  void add_path(char *path) {
    while(char *part = rindex(path, '/')) {
      part[0] = 0;
      part = strdup(part+1);
      if(dirs[path]){
        dirs[path]->push_back(part);
        break;
      } else {
        dirs.set(path, new std::vector<char*>());
        dirs[path]->push_back(part);
      }
    }
    free(path);
  }
  
  packfs() {
    std::vector<char*> *root = new std::vector<char*>();
    dirs.set("", root);
    dirs.set("/", root);
  }

  void process_pack_archive(pack_archive *pack) {
    printf("Loading pack %s\n", pack->path);
    for(uint i=0; i<pack->files.size(); i++)
      add_file(pack->files[i]);
  }

  /* Respect pack type order, then follow cmdline order */
  void process_packs() {
    for(uint pt=0; pt<=5; pt++)
      for(uint j=0; j<packs.size(); j++)
        if(pt == packs[j]->pack_type)
          process_pack_archive(packs[j]);
  }
};

/* Nasty global forwarding functions */
packfs *fs;

int packfs_readdir(__const char *path, void *buf, fuse_fill_dir_t filler, off_t offset, struct fuse_file_info *fi) {
  std::vector<char*> *dir = fs->dirs[path];
  if(!dir) return -2;
  filler(buf, ".", NULL, 0);
  filler(buf, "..", NULL, 0);
  for(uint i=0; i<dir->size(); i++)
    filler(buf, (*dir)[i], NULL, 0);
  return 0;
}

int packfs_getattr(const char *path, struct stat *stbuf) {
  memset((void*)stbuf, 0, sizeof(struct stat));
  if(fs->dirs[path]){
    stbuf->st_mode = S_IFDIR | 0555;
    stbuf->st_nlink = 2;
    return 0;
  }
  packfs_file *file = fs->files[path];
  if(!file) return -ENOENT;
  return file->getattr(stbuf);
}

int packfs_open(const char *path, struct fuse_file_info *fi) {
  if (!fs->files[path]) return -ENOENT;
  if ((fi->flags & O_ACCMODE) != O_RDONLY) return -EACCES;
  return 0;
}

int packfs_read(const char *path, char *buf, size_t size, off_t offset, struct fuse_file_info *fi) {
  packfs_file *file = fs->files[path];
  if (!file) return -ENOENT;
  return file->xread(buf, size, offset);
}

int main(int argc, char **argv) {
  fs = new packfs();
  char *fuse_argv[2] = {argv[0], argv[argc-1]};
  for(int i=1; i<argc-1; i++) {
    fs->packs.push_back(new pack_archive(argv[i]));
  }
  fs->process_packs();
  
  struct fuse_operations packfs_ops;
  memset((void*)&packfs_ops, 0, sizeof(struct fuse_operations));
  packfs_ops.readdir = packfs_readdir;
  packfs_ops.getattr = packfs_getattr;
  packfs_ops.open    = packfs_open;
  packfs_ops.read    = packfs_read;
  
  return fuse_main(2, fuse_argv, &packfs_ops, NULL);
}
