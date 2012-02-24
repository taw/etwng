Format documentation and Python 3 converter by alpaca can be downloaded here:
* http://www.twcenter.net/forums/showthread.php?t=359814

This is Ruby converter with pretty much the same functionality,
except more strict floating point rounding (so results are bit-wise identical),
slightly different text format,
and interface more similar to my other converters.

Usage:

jruby rigid_spline_unpack foo.rigid_spline foo.txt
jruby rigid_spline_unpack directory_in directory_out

jruby rigid_spline_pack foo.txt foo.rigid_spline
jruby rigid_spline_pack directory_in directory_out
