require "lib/binary_stream"

# Converter needs multiple formats, at least:
# * ETW binary
# * low-level Ruby - for transformations, testing etc.
# * either a single XML,
#   or directory with XMLs and dependent documents
#
# That of course before considering performance hacks

class Converter
  attr_reader :stream
  def initialize(stream)
    @stream = stream
  end
  
  def self.pack(data)
    BinaryStreamWriter.open do |stream|
      conv = new(stream)
      conv.pack_data(data)
    end
  end

  def self.unpack(data)
    BinaryStreamReader.open(data) do |stream|
      conv = new(stream)
      conv.unpack_data
    end
  end
end
