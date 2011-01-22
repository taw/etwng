#!/usr/bin/env ruby

require "rubygems"
require "nokogiri"
require "pp"
require "pathname"

class TableSchema
end

class DbSchemata
  def initialize
    @doc = Nokogiri::XML.parse(File.open('DB.xsd', 'rb', &:read))
    @doc.remove_namespaces!
    @schema = {}
    @doc.xpath('/schema/complexType').each{|ct|
      @schema[ct['name']] = parse_complex_type_node(ct)
    }
  end
  
  def get_schema(table_name, version)
    return nil unless @schema[table_name]
    @schema[table_name].map{|name, min_version, type|
      version >= min_version ? [name, type] : nil
    }.compact
  end
  
  class <<self
    def instance
      @instance ||= new
    end
  end

private
  def parse_complex_type_node(complex_type_node)
    @fields = complex_type_node.xpath("attribute").map{|a| parse_field_node(a) }
  end

  def field_extract_optional(field_ht)
    required = field_ht.delete("use") == "required"
    optional = field_ht.delete("Optional") == "true"
    raise "Field must be either required or optional" unless required or optional
    raise "Field cannot be both required and optional" if required and optional
    optional
  end

  def parse_field_node(field_node)
    field = {}
    field_node.attributes.each{|k,v| field[k] = v.value }

    name     = field.delete("name")
    version  = field.delete("VersionStart")
    version  = version.to_i if version
    optional = field_extract_optional(field)
    type     = field.delete("type").sub(/\Axs:/, "")
    bloblen  = field.delete("BlobLength")

    if type == "string"
      raise "Blobs cannot be optional" if optional and bloblen
      if optional
        type = "optstring"
      elsif bloblen
        type = "blob:#{bloblen}"
      end
    else
      raise "Only strings can be optional, not #{type}" if optional
      raise "Only strings can have blob length, not #{type}" if bloblen
    end

    [name, version||1, type]
  end
end
