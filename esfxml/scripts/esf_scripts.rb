require "rubygems"
require "nokogiri"

class File
  def self.write(path, content)
    File.open(path, 'wb') do |fh|
      fh.write(content)
    end
  end
end

class EsfScript
  attr_reader :xmldir
  
  def initialize(xmldir)
    raise "#{xmldir} doesn't exist" unless File.directory?(xmldir)
    raise "#{xmldir} doesn't look like unpacked esf file" unless File.exist?(xmldir + "/esf.xml")
    @xmldir = xmldir
  end

  def each_file(glob, &blk)
    Dir[xmldir + "/" + glob].sort.select{|file_name| File.file?(file_name)}.each(&blk)
  end
  
  def update_file(file_name)
    content = File.open(file_name, 'rb', &:read)
    new_content = yield(content)
    if content != new_content
      File.write(file_name, new_content)
    end
  end

  def update_each_xml(glob, xpath)
    each_file(glob) do |file_name|
      update_file(file_name) do |content|
        doc = Nokogiri::XML.parse(content)
        changed = false
        doc.xpath(xpath).each do |elem|
          changed = true if yield(elem)
        end
        if changed
          doc.to_s
        else
          content
        end
      end
    end
  end

  def update_faction(faction_to_change)
    update_each_xml("factions/*.xml", "//rec[@type='FACTION']") do |faction|
      faction_name = faction.xpath("rec[@type='CAMPAIGN_PLAYER_SETUP']/s")[0].text
      next unless faction_to_change == faction_name
      yield(faction)
    end
  end
end
