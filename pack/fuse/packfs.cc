#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <fuse.h>
#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/types.h>

struct file_in_a_pack
{
  char *path;
  uint64_t ofs;
  uint32_t size;
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
  struct file_in_a_pack *files;  
  
  
  pack_file(const char *_path) {
    path = _path;
    fh = force_open(path);

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

    // printf("Pack file %s, type: %d\n", path, pack_type);
    load_deps();
    load_files();
  }

  ~pack_file() {
    free(files);
    free(dep_names);
  }

private:
  void load_deps() {
    char *deps_header_data = (char*)malloc(deps_size);
    force_read(deps_header_data, deps_size);
    dep_names = (char**)malloc(sizeof(char*) * deps_count);
    
    // printf("Deps: %d/%d\n", deps_size, deps_count);
    for(uint i=0,j=0; i<deps_count; i++) {
      dep_names[i] = strdup(deps_header_data+j);
      j += strlen(dep_names[i]) + 1;
      //printf("Dep: %s\n", dep_names[i]);
    }
    
    free(deps_header_data);
  }
  
  void load_files() {
    char *files_header_data = (char*)malloc(files_size);
    force_read(files_header_data, files_size);
    files = (struct file_in_a_pack *)malloc(sizeof(struct file_in_a_pack) * files_count);

    // printf("Files: %d/%d\n", files_size, files_count);
    uint64_t ofs = 24 + deps_size + files_size;
    for(uint i=0, j=0; i<files_count; i++) {
      files[i].ofs =  ofs;
      files[i].size =  *(uint32_t*)(files_header_data+j);
      files[i].path =  strdup(files_header_data+j+4);
      ofs += files[i].size;
      j += strlen(files[i].path) + 5;
      adjust_slashes(files[i].path);
      // printf("File %d of %d: %s, ofs %lld, size %d\n", i, files_count, files[i].path, files[i].ofs, files[i].size);
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




class packfs
{
public:
  pack_file *packs[3];

  uint files_count;
  file_in_a_pack *files;
  
  packfs() {
    packs[0] = new pack_file("/Users/taw/all/etw_unpacker/ext/main.pack");
    packs[1] = new pack_file("/Users/taw/all/etw_unpacker/ext/patch.pack");
    packs[2] = new pack_file("/Users/taw/all/etw_unpacker/ext/patch2.pack");
    
    /* no merging code yet */
    files_count = packs[0]->files_count;
    files = packs[0]->files;
  }
  
  file_in_a_pack *find_file(const char *path) {
    for(uint i=0; i<files_count; i++) {
      if(0 == strcmp(1+path, files[i].path)){
        return &files[i];
      }
    }
    return NULL;
  }
};


/* Nasty global forwarding functions */
packfs *fs;

int packfs_readdir(__const char *path, void *buf, fuse_fill_dir_t filler, off_t offset, struct fuse_file_info *fi) {
  if (strcmp(path, "/") != 0) 
    return -2;

  filler(buf, ".", NULL, 0);
  filler(buf, "..", NULL, 0);

  for(uint i=0; i<fs->files_count; i++) {
    filler(buf, fs->files[i].path, NULL, 0); 
  }

  return 0;
}

int packfs_getattr(const char *path, struct stat *stbuf)
{
  memset((void*)stbuf, 0, sizeof(struct stat));

  if (strcmp(path, "/") == 0) { /* The root directory of our file system. */
    stbuf->st_mode = S_IFDIR | 0555;
    stbuf->st_nlink = 2 + fs->packs[0]->files_count;
    return 0;
  }
  
  file_in_a_pack *file = fs->find_file(path);

  if(file) {
    stbuf->st_mode = S_IFREG | 0444;
    stbuf->st_nlink = 1;
    stbuf->st_size = file->size;
    return 0;
  } else {
    return -ENOENT;
  }
}

int packfs_open(const char *path, struct fuse_file_info *fi)
{
  file_in_a_pack *file = fs->find_file(path);
  if (!file)
    return -ENOENT;

  if ((fi->flags & O_ACCMODE) != O_RDONLY)
    return -EACCES;

  return 0;
}

// size_t off_t uint32 uint64 -> huge mess right now, needs fixing
int packfs_read(const char *path, char *buf, size_t size, off_t offset, struct fuse_file_info *fi)
{
  file_in_a_pack *file = fs->find_file(path);
  if (!file)
    return -ENOENT;

  if (offset >= file->size)
    return 0;

  if (offset + size > file->size)
      size = file->size - offset;

  if(-1 == lseek(fs->packs[0]->fh, file->ofs + offset, SEEK_SET)) {
    return -EIO;
  }
  return read(fs->packs[0]->fh, buf, size);
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
