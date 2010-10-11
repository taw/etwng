require "pp"
require "fileutils"
require "find"

EsfFormats = %W[
.prop_list
.farm_template_tile
.building_list
.ai_hints
.farm_manager
.tree_list
.dat
.deployment_areas
.settings
]

EsfFiles = %W[
  pathfinding.esf
  poi.esf
  regions.esf
  sea_grids.esf
  trade_routes.esf
]

CntFormats = %W[
  .anim_sound_event
  .rigid_model_animation
  .desc_model
  .rigid_model
  .animatable_rigid_model
  .farm_fields_tile_texture
  .rigid_naval_model
  .windows_model
]

SplineFormats = %W[
  .variant_part_mesh
  .unit_variant
  .sfk
  .rigid_spline
]

class FileFormatDetection
  def initialize(samples_dir)
    FileUtils.mkdir_p samples_dir
    @samples_dir = samples_dir
  end
  
  # These need to point to correct directories
  def etw_paths
    @etw_paths ||= %W[~/.etw/ ~/.etwfs/ ~/.ntw/ ~/.ntwfs/].map{|fn| File.expand_path(fn)+"/"}.select{|fn| File.exist?(fn)}
  end
  
  def has_sample?(fn)
    if fn[0,1] == "."
      return true if !Dir["#{@samples_dir}/*#{fn}"].empty?
    else
      return true if File.exist?("#{@samples_dir}/#{fn}")
    end
    false
  end
  
  def all_formats
    (EsfFormats + EsfFiles + CntFormats + SplineFormats)
  end
  
  def verify_samples!
    all_formats.each{|fmt|
      puts "#{fmt} - #{has_sample?(fmt) ? 'OK' : 'MISSING'}"
    }
  end
  
  def get_missing_samples!
    available_files = {}
    etw_paths.map{|dir|
      Find.find(dir){|fn|
        (available_files[File.basename(fn)] ||= []) << fn
        (available_files[File.extname(fn)] ||= []) << fn
      }
    }
    all_formats.each{|fmt|
      if has_sample?(fmt)
        puts "Already OK - #{fmt}"
      elsif available_files[fmt]
        fn0 = available_files[fmt].min
        puts "Candidates for #{fmt}: #{available_files[fmt].size}, first is #{fn0}"
        FileUtils.cp fn0, @samples_dir, :verbose => true
      else
        puts "No samples of #{fmt} found"
      end
    }
  end
end
