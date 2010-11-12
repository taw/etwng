require "pp"
require "fileutils"
require "find"

require "lib/binary_stream"
require "lib/converter"
require "lib/esf_file"
require "lib/farm_fields_tile_texture_file"
require "lib/desc_model_file"
require "lib/anim_sound_event"
require "lib/spln"
require "lib/rigid_model_bounds"
require "lib/rigid_model_header"
require "lib/loc"
require "lib/rigid_mesh"
require "lib/atlas_converter"
require "lib/anim"
require "lib/sound_events"

SupportedFormats = {
# Esf extensions
  ".prop_list"               => EsfFile,
  ".farm_template_tile"      => EsfFile,
  ".building_list"           => EsfFile,
  ".ai_hints"                => EsfFile,
  ".farm_manager"            => EsfFile,
  ".tree_list"               => EsfFile,
  ".deployment_areas"        => EsfFile,
  ".settings"                => EsfFile,
  ".bmd_definition"          => EsfFile,

  # There are different kinds of .dat, some are .esf but not all
  # ".dat"                     => EsfFile,

# Esf special files
  "pathfinding.esf"          => EsfFile,
  "poi.esf"                  => EsfFile,
  "regions.esf"              => EsfFile,
  "sea_grids.esf"            => EsfFile,
  "trade_routes.esf"         => EsfFile,


# Cnt-prefix simple formats
  ".anim_sound_event"         => AnimSoundEventConverter,
  ".desc_model"               => DescModelConverter,

  # Totally broken
  # "sound_events"             => SoundEventsConverter, 

# Rigid model
  # ".rigid_model_animation"    => RigidModelConverter, # SAME as .rigid_model ???
  # ".rigid_model"              => RigidModelConverter,
  # ".animatable_rigid_model"   => RigidModelConverter,

# FFTT (not all subtypes supported)
  ".farm_fields_tile_texture" => FarmFieldsTileTextureConverter,

# Spline formats
  ".rigid_spline"             => SplnConverter,

# What are these ?
  ".rigid_model_header"      => RigidModelHeaderConverter,
  ".rigid_model_bounds"      => RigidModelBoundsConverter,
  ".loc"                     => LocConverter,
  ".rigid_mesh"              => RigidMeshConverter,
  ".atlas"                   => AtlasConverter,
  ".anim"                    => AnimConverter,

  
  ".rigid_naval_model"        => nil,
  ".windows_model"            => nil,
  ".variant_weighted_mesh"   => nil,
  ".spt"                     => nil,
  ".weighted_mesh"           => nil,
  ".hf"                      => nil,
  ".cuf"                     => nil,
  ".rigid_trees"             => nil,
  ".tree_model"              => nil,
  ".fogvolume_mesh"          => nil,

# Similar tags, but definitely not splines
  ".variant_part_mesh"        => nil, # VmpfConverter,
  ".unit_variant"             => nil, # VrntConverter,
  ".sfk"                      => nil, # SfpkConverter,
}

class FileFormatDetection
  def initialize(samples_dir)
    FileUtils.mkdir_p samples_dir
    @samples_dir = samples_dir
  end
  
  def converter_for(fn)
    en = File.extname(fn)
    bn = File.basename(fn)

    fails = %W[
      bunker_hill_blend_field.farm_fields_tile_texture
      bunker_hill_grass_field.farm_fields_tile_texture
      eu_east_winter_grass_building.farm_fields_tile_texture
      eu_east_winter_grass_road.farm_fields_tile_texture
      eu_north_winter_grass_building.farm_fields_tile_texture
      eu_north_winter_grass_road.farm_fields_tile_texture
      eu_south_winter_grass_building.farm_fields_tile_texture
      eu_south_winter_grass_road.farm_fields_tile_texture
      eu_west_winter_grass_building.farm_fields_tile_texture
      eu_west_winter_grass_road.farm_fields_tile_texture
      ottoman_winter_grass_building.farm_fields_tile_texture
      ottoman_winter_grass_road.farm_fields_tile_texture
    ]
    return nil if fails.include?(bn)
    
    conv = SupportedFormats[bn] || SupportedFormats[en]

    if conv.nil? and false
      puts "What is #{fn} [#{File.size(fn)} bytes]?"
      system "hexdump -C #{fn}| head -n 64"
    end

    return conv
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
  
  def verify_samples!
    SupportedFormats.each{|fmt,conv|
      puts "#{fmt} - #{has_sample?(fmt) ? 'OK' : 'MISSING'}"
    }
  end

  def save_sample!(fn)
    fnt = "#{@samples_dir}/#{File.basename(fn)}"
    if File.exist?(fnt)
      puts "Already sampled: #{fn}"
    else
      FileUtils.cp fn, fnt, :verbose => true
    end
  end
  
  def get_missing_samples!
    available_files = {}

    SupportedFormats.each{|fmt,conv|
      available_files[fmt] = []
    }

    etw_paths.map{|dir|
      Find.find(dir){|fn|
        bn = File.basename(fn)
        en = File.extname(fn)
        available_files[en] << [File.size(fn), fn] if  available_files[en]
        available_files[bn] << [File.size(fn), fn] if  available_files[bn]
      }
    }
    available_files.each{|fmt, avail|
      if fmt == ".farm_fields_tile_texture"
        avail.map{|sz,fn| fn}.uniq.each{|fn|
          save_sample!(fn)
        }
      elsif !avail.empty?
        fns = avail.sort[0,5].map{|sz,fn| fn} +
              avail.map{|sz,fn| fn}.sort[0,5]
        fns.uniq.each{|fn|
          save_sample!(fn)
        }
      else
        puts "No samples of #{fmt} found"
      end
    }
  end
end
