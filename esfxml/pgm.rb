class File
  class <<self
    def write(path, data)
      open(path, 'wb') do |fh|
        fh.write data
      end
    end
    def pgm_header(xsz,ysz)
      "P5\n#{xsz} #{ysz}\n255\n"
    end
    def write_pgm(path,xsz,ysz,data)
      warn "PGM #{path} has size #{xsz}x#{ysz} (#{xsz*ysz}) but data has #{data.size} bytes" unless xsz*ysz == data.size
      open(path, 'wb'){|fh|
        fh.write pgm_header(xsz,ysz)
        fh.write data
      }
    end
    def read_pgm(path)
      File.open(path, 'rb'){|fh|
        p5    = fh.readline
        sizes = fh.readline
        px    = fh.readline
        data  = fh.read
        raise "Not proper header" unless p5 == "P5\n" and px == "255\n" and sizes =~ /\A(\d+) (\d+)\n\z/
        return [$1.to_i, $2.to_i, data]
      }
    end
  end
end
