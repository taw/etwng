#!/usr/bin/env python3.1
import struct, os, sys

# For easy file reading and writing interactions
def read_long(fhandle):
  return struct.unpack('<l', fhandle.read(4))[0]

def read_cstr(handle):
  char = ''
  filename = ''
  flen = 0
  while char != b'\x00':
    char = handle.read(1)
    if (char != b'\x00'):
      filename += char.decode()
    flen += 1
  return (filename, flen)


def removeDir(path):
  # remove all files in a folder
  if not (os.path.isdir(path)):
    return True
  files = os.listdir(path)
  for x in files:
    fullpath=os.path.join(path, x)
    if os.path.isfile(fullpath):
      os.remove(fullpath)
    elif os.path.isdir(fullpath):
      removeDir(fullpath)
  os.rmdir(path)

def copy_data(source, dest, offset, length):
  source.seek(offset)
  for i in range(length//(2**20)):
    dest.write(source.read(2**20))
  j = (length%(2**20))
  if j:
    dest.write(source.read(j))
  

def saveFile(handle, outputdir, path, length, offset):
  path = path.replace("\\", "/")
  print('Exporting '+path+', length: '+str(length)+', at offset: '+str(offset))
  
  # create output directory 
  dir = os.path.split(os.path.join(outputdir, path))[0]
  if not os.path.isdir(dir):
    os.makedirs(dir)

  output = open(os.path.join(outputdir,path),'wb')
  copy_data(handle, output, offset, length)
  output.close()

def unpackPackArchive(pack_path, outputdir):
  handle      = open(pack_path,"rb")
  magic       = read_long(handle)
  mod_type    = read_long(handle)
  deps_count  = read_long(handle)
  deps_len    = read_long(handle)
  files_count = read_long(handle)
  files_len   = read_long(handle)

  if magic == 843597392 or magic == 860374608:
    header_len = 32 + deps_len + files_len
    handle.seek(32 + deps_len)
  else:
    header_len = 24 + deps_len + files_len
    handle.seek(24 + deps_len)

  offset = header_len
  files = []
  for i in range(files_count):
    # read length of file
    data_len = read_long(handle)
    fn, fn_len = read_cstr(handle)
    files.append((fn, data_len, offset))
    offset += data_len

  for (path,length,offset) in files:
    saveFile(handle, outputdir, path, length, offset)

# main
for fn in sys.argv[1:]:
  dn = "unpacked/"+fn.split("/")[-1].replace(".pack", "")
  if dn:
    removeDir(dn)
  os.makedirs(dn)
  unpackPackArchive(fn, dn)
