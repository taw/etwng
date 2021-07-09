require "set"

class TaskFilter
  def initialize(expr)
    if expr.include?("/")
      @path = Pathname(__dir__).parent + Pathname(expr)
    elsif expr =~ /\A[,\d+\-]+\z/
      @versions = expr.split(",").flat_map{|e|
        if e =~ /\A(\d+)\z/
          $1.to_i
        elsif e =~ /\A(\d+)-(\d+)\z/
          [*$1.to_i..$2.to_i]
        else
          raise "Filter expression parse error: #{expr}"
        end
      }.to_set
    else
      raise "Filter expression parse error: #{expr}"
    end
  end

  def match?(file_task)
    if @path
      file_task.paths.include?(@path)
    elsif @versions
      @versions.include?(file_task.version)
    else
      raise "Bad filter"
    end
  end
end
