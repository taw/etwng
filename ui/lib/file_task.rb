require "pathname"

class FileTask
  attr_reader :data_path

  def initialize(data_path)
    @data_path = Pathname(data_path)
  end

  def version
    unless @version
      unless @data_path.read(10) =~ /\AVersion(\d\d\d)\z/
        raise "No magic header present"
      end
      @version = $1.to_i(10)
    end
    @version
  end

  def fc?
    @data_path.extname == ".fc"
  end

  def cml?
    @data_path.extname == ".cml"
  end

  def twui_images?
    @data_path.to_s.end_with?(".twui.images")
  end

  def ui?
    (not fc?) and (not cml?) and (not twui_images?)
  end

  def supported_by_converter?
    ui? and [32, 33, 39, 43, 44, 46, 47, 49, 50, 51, 52, 54].include?(version)
  end

  def supported_by_ui2xml?
    fc? or cml? or twui_images? or [*25..129].include?(version)
  end

  def full_version
    if cml?
      "cml"
    elsif fc?
      "fc"
    elsif twui_images?
      "twui_images"
    else
      ""
    end + ("%03d" % version)
  end

  def game
    @data_path.dirname.basename.to_s
  end

  def basename
    @data_path.basename.to_s
  end

  # These names are a bit dumb tbh

  def converted_root
    Pathname(__dir__).parent + "converted"
  end

  def recreated_root
    Pathname(__dir__).parent + "tmp/recreated"
  end

  def output_root
    Pathname(__dir__).parent + "output"
  end

  def unpacked_root
    Pathname(__dir__).parent + "unpacked"
  end

  def output_path
    @output_path ||= output_root + full_version + "#{game}-#{basename}.txt"
  end

  def converted_path
    @converted_path ||= converted_root + full_version + "#{game}-#{basename}.xml"
  end

  def converted_fail_path
    @converted_fail_path ||= converted_root + full_version + "#{game}-#{basename}.fail"
  end

  def unpacked_path
    @unpacked_path ||= unpacked_root + full_version + "#{game}-#{basename}.xml"
  end

  def unpacked_fail_path
    @unpacked_fail_path ||= unpacked_root + full_version + "#{game}-#{basename}.fail"
  end

  def recreated_path
    @recreated_path ||= recreated_root + full_version + "#{game}-#{basename}"
  end

  # We want absolute paths here
  def paths
    @paths ||= [
      data_path,
      output_path,
      converted_path,
      converted_fail_path,
      unpacked_path,
      unpacked_fail_path,
      recreated_path,
    ]
  end

  def data_size
    data_path.size
  end
end
