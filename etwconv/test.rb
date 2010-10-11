puts "Testing #{RUBY_PLATFORM}/#{RUBY_VERSION}"
$: << "."

require "lib/core_ext"

require "test/platform_test"
require "test/binary_stream_test"
require "test/farm_fields_tile_texture_file_test"
require "test/esf_file_test"
