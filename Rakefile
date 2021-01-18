require "pathname"
task "default" => "test"
task "spec" => "test"

def trash(*paths)
  system "trash", *paths
end

file "luac/luadec" do
  Dir.chdir("luac") do
    sh "./build_luadec"
  end
end

file "pack/fuse/packfs" do
  Dir.chdir("pack/fuse") do
    sh "make"
  end
end

# No point building luadec anymore
desc "Run tests"
task "test" => ["pack/fuse/packfs"] do
  raise "Can't see packfs" unless Pathname("pack/fuse/packfs").exist?
end

desc "clean up build files"
task "clean" do
  trash "pack/fuse/packfs", "pack/fuse/packfs.dSYM"
  trash "luac/build", "luac/src", "luac/luadec"
end
