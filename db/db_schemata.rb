#!/usr/bin/env ruby

require "rubygems"
require "nokogiri"
require "pp"
require "pathname"
require "fileutils"

class DbSchemata
  def initialize
    @doc = Nokogiri::XML.parse(File.open('DB.xsd', 'rb', &:read))
    @schema = {}
    @doc.xpath('/xs:schema/xs:complexType').each{|ct|
      @schema[ct['name']] = parse_complex_type_node(ct)
    }
  end

  def get_schema(table_name, version, guid)
    return nil unless @schema[table_name]
    # max_version_known = @schema[table_name].map{|name, min_version, type| min_version}.max
    # if version > max_version_known
    #   puts "#{table_name} schema known up to version #{max_version_known} but #{version} requested, please update"
    #   return nil
    # end
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
    @fields = complex_type_node.xpath("xs:attribute").map{|a| parse_field_node(a, complex_type_node['name']) }
  end

  def field_extract_optional(field_ht, debug=nil)
    required = field_ht.delete("use") == "required"
    optional = field_ht.delete("Optional") == "true"
    raise "Field must be either required or optional: #{debug}" unless required or optional
    raise "Field cannot be both required and optional: #{debug}" if required and optional
    optional
  end

  def parse_field_node(field_node, table)
    field = {}
    field_node.attributes.each{|k,v| field[k] = v.value }

    name     = field.delete("name")
    version  = field.delete("VersionStart")
    version  = version ? version.to_i : 1
    optional = field_extract_optional(field, "#{table}.#{name}")
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

    [name, version, type]
  end
end
