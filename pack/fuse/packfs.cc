#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <fuse.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/types.h>

#include <hash_map.h>

struct packfs_file
{
  char *path;
  int fh;
  off_t  ofs;
  size_t size;
  time_t atime;
  time_t ctime;
  time_t mtime;
};

class pack_file
{
public:

  const char *path;
  int fh;

  uint32_t pack_type;
  uint32_t deps_size, deps_count;
  uint32_t files_size, files_count;

  char **dep_names;
  struct packfs_file *files;  

  struct stat stbuf;
  
  pack_file(const char *_path) {
    path = _path;

    fh = force_open(path);
    if(0 != fstat(fh, &stbuf)) {
      fprintf(stderr, "Error getting pack file metadata %s: %s\n", path, strerror(errno));
      exit(1);
    }

    load_header();
    load_deps();
    load_files();
  }

  ~pack_file() {
    free(files);
    free(dep_names);
  }

private:
  void load_header() {
    uint32_t header[6];
    force_read((char*)header, 24);
   
    if(header[0] != *(uint32_t*)("PFH0")) {
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
    char *deps_header_data = (char*)malloc(deps_size);
    force_read(deps_header_data, deps_size);
    dep_names = (char**)malloc(sizeof(char*) * deps_count);
    
    for(uint i=0,j=0; i<deps_count; i++) {
      dep_names[i] = strdup(deps_header_data+j);
      j += strlen(dep_names[i]) + 1;
    }
    free(deps_header_data);
  }
  
  void load_files() {
    char *files_header_data = (char*)malloc(files_size);
    force_read(files_header_data, files_size);
    files = (struct packfs_file *)malloc(sizeof(struct  packfs_file) * files_count);

    off_t ofs = 24 + deps_size + files_size;
    for(uint i=0, j=0; i<files_count; i++) {
      files[i].fh = fh;
      files[i].ofs =  ofs;
      files[i].atime = stbuf.st_atime;
      files[i].mtime = stbuf.st_mtime;
      files[i].ctime = stbuf.st_ctime;
      files[i].size =  *(uint32_t*)(files_header_data+j);
      files[i].path =  strdup(files_header_data+j+4);
      ofs += files[i].size;
      j += strlen(files[i].path) + 5;
      adjust_slashes(files[i].path);
    }
    free(files_header_data);
  }
  
  void adjust_slashes(char *path)
  {
    int len = strlen(path);
    for(int i=0; i<len; i++) {
      if (path[i] == '/' || path[i] == '\\') {
        path[i] = '-';
      }
    }
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


struct eqstr
{
  bool operator()(const char* s1, const char* s2) const
  {
    return strcmp(s1, s2) == 0;
  }
};


class packfs
{
public:
  pack_file *packs[3];

  hash_map<const char*, packfs_file*, hash<const char*>, eqstr> files;
  
  packfs() {
    packs[0] = new pack_file("packs/main.pack");
    packs[1] = new pack_file("packs/patch.pack");
    packs[2] = new pack_file("packs/patch2.pack");
    
    for(uint j=0; j<3; j++) {
      for(uint i=0; i<packs[j]->files_count; i++) {
        packfs_file *file = &packs[j]->files[i];
        files[file->path] = file;
      }
    }
  }
};

/* Nasty global forwarding functions */
packfs *fs;

int packfs_readdir(__const char *path, void *buf, fuse_fill_dir_t filler, off_t offset, struct fuse_file_info *fi) {
  if (strcmp(path, "/") != 0) 
    return -2;

  /* Don't report one file multiple times */
  for(uint j=0; j<3; j++) {
    for(uint i=0; i<fs->packs[j]->files_count; i++) {
      packfs_file *file = &fs->packs[j]->files[i];
      if(fs->files[file->path] == file) {
        filler(buf, file->path, NULL, 0);
      }
    }
  }


  filler(buf, ".", NULL, 0);
  filler(buf, "..", NULL, 0);

  return 0;
}

int packfs_getattr(const char *path, struct stat *stbuf)
{
  memset((void*)stbuf, 0, sizeof(struct stat));

  if (strcmp(path, "/") == 0) { /* The root directory of our file system. */
    stbuf->st_mode = S_IFDIR | 0555;
    stbuf->st_nlink = 2;
    return 0;
  }
  
  packfs_file *file = fs->files[path+1];

  if(file) {
    stbuf->st_mode  = S_IFREG | 0444;
    stbuf->st_nlink = 1;
    stbuf->st_size  = file->size;
    stbuf->st_ctime = file->ctime;
    stbuf->st_mtime = file->mtime;
    stbuf->st_atime = file->atime;
    return 0;
  } else {
    return -ENOENT;
  }
}

int packfs_open(const char *path, struct fuse_file_info *fi)
{
  packfs_file *file = fs->files[path+1];
  if (!file)
    return -ENOENT;

  if ((fi->flags & O_ACCMODE) != O_RDONLY)
    return -EACCES;

  return 0;
}

int packfs_read(const char *path, char *buf, size_t size, off_t offset, struct fuse_file_info *fi)
{
  packfs_file *file = fs->files[path+1];
  if (!file)
    return -ENOENT;

  if (offset >= file->size)
    return 0;

  if (offset + size > file->size)
      size = file->size - offset;

  if(-1 == lseek(file->fh, file->ofs + offset, SEEK_SET))
    return -EIO;

  return read(file->fh, buf, size);
}


int main(int argc, char **argv)
{
  fs = new packfs();
  
  struct fuse_operations packfs_ops;
  memset((void*)&packfs_ops, 0, sizeof(struct fuse_operations));
  
  packfs_ops.readdir = packfs_readdir;
  packfs_ops.getattr = packfs_getattr;
  packfs_ops.open    = packfs_open;
  packfs_ops.read    = packfs_read;
  
  return fuse_main(argc, argv, &packfs_ops, NULL);
}
