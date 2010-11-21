== Usage ==
$ ./esf2xml foo.esf foo_dir
$ ./esf2xml --quiet foo.esf foo_dir
$ ./xml2esf foo_dir foo.esf

esf2xml automatically prints progressbar unless told not to by --quiet option
(xml2esf might get this too later)

To run with specific Ruby version use like:
$ ruby ./esf2xml foo.esf foo_dir
$ jruby --server -J-Xmx2048m ./esf2xml foo.esf foo_dir

You might want to specify higher memory limit like -J-Xmx2048m option,
default JVM max heap size is ridiculously small 500MB, half of it
going to JVM overhead.

Passing --server to jruby speeds it up by about 10%, so do it.

== Unpacked Directory ==
Main file in unpacked directory is always esf.xml
There might be other files as well, xml, bitmap, or anything else.

== System Requirements ==
It should now work on every system (by every I mean OSX, Linux, and Windows) both ways.

For reasonably recent OSX (10.5 or newer) and Linux esf2xml should work out of the box,
for xml2esf you only need to run this command, or install nokogiri some other way:
$ sudo gem install nokogiri

The easiest way to get it running under Windows is by installing
JRuby single installer with Java Runtime Environment bundled.
Here's the link:
http://jruby.org.s3.amazonaws.com/downloads/1.5.3/jruby_windowsjre_1_5_3.exe

You might still need to install nokogiri:
$ jgem install nokogiri --pre

For Windows JRuby you need prerelease version of Nokogiri (--pre flag).
If you have installed other version before, please uninstall it first:
$ jgem uninstall nokogiri


== Rest of the file ==
NOTE: Past this line, this README file has very little to do with actual code.

== XML structure ==

Every file starts with header like this:

<esf magic='43982 0 1232650587'>
 <node_types>
  <node_type name='root' />
  <node_type name='theatres_and_region_keys' />
  <node_type name='theatre' />
  <node_type name='region_keys' />
  <node_type name='theatres' />
  <node_type name='climate_map' />
  <node_type name='wind_map' />
  <node_type name='transition_areas' />
  ...
 </node_types>
 
It's only used for getting exact binary copies back and could 
in principle be regenerated.


Then you have basic types like:

 <s>628219853</s>
 <v2 y='0.0' x='-760.0' />
 <no />
 <u>1750</u>
 <i4_ary size='11'>0 0 0 0 0 0 0 0 0 0 0</i4_ary>


uN - unsigned N-byte integer
iN - signed N-byte integer
yes/no are booleans
byte - 1-byte unsigned integer

s is utf-8 (converted to utf-16le in esf)
asc is ascii (enforced only iso-8859-1 really)

flt/v2/v3 are single precision floats and their tuples

X_ary - array of X, size argument is to prevent accidental overwrites,
  some of these fields are fixed size, others are not.
bin are other array-like structures, printed in hex

Composites fields:

<ary> - contains 0 or more <rec>s of same kind
<rec> - contains some number of heterogenous fields

Some constant-schema records and elements get first level tags, like
  <REGION_OWNERSHIPS region='iroquois_territory' faction='iroquoi' />
which is really
  <rec type="REGION_OWNERSHIPS">
    <s>iroquois_territory</s>
    <s>iroquoi</s>
  </rec>

array/record/and record-based own elements have flags field which is used
for esf byte-perfect compatibility. I'm not sure what it's used for, but it
seems to be highly systematic and not random at all.


== Future ==

XML would be more useful if it was more semantic and less low-level.
Obvious areas for improvement:
* record types with multiple varieties (usually one for presence and
  one for absence of something) - like CAMPAIGN_LOCALISATION.
  Why present localisation is ["str"], but absent is ["empty_str", "empty_str"] ???
* QUAD_TREE_BIT_ARRAY_NODE
* some more meaningful representation of embedded binary data than hex dump
* something between all-attributes and all-children nodes
* not printing default trivial values to make it faster
* Higher performance
* (some way to run it on Windows)
* Some numbers are not numbers but references or bitfields or something else,
  mark them differently.
* Things in XML in general shouldn't depend on position in non-trivial way,
  see DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY.

Both better quality XML and higher performance both require smarter architecture,
and need to move together.

== A few samples ==

<rec type='REGION_OWNERSHIPS_BY_THEATRE'>
 <s>america</s>
 <ary version='0' type='REGION_OWNERSHIPS'>
  <REGION_OWNERSHIPS region='iroquois_territory' faction='iroquoi' />
  <REGION_OWNERSHIPS region='great_plains' faction='plains' />
  <REGION_OWNERSHIPS region='new_england' faction='thirteen_colonies' />
  <REGION_OWNERSHIPS region='french_guyana' faction='france' />
  <REGION_OWNERSHIPS region='lower_louisiana' faction='louisiana' />
  <REGION_OWNERSHIPS region='hispaniola' faction='spain' />
  <REGION_OWNERSHIPS region='northwest_territories' faction='huron' />
  <REGION_OWNERSHIPS region='ruperts_land' faction='britain' />
  <REGION_OWNERSHIPS region='tejas' faction='pueblo' />
  <REGION_OWNERSHIPS region='upper_louisiana' faction='louisiana' />
  <REGION_OWNERSHIPS region='dutch_guyana' faction='netherlands' />
  <REGION_OWNERSHIPS region='virginia' faction='thirteen_colonies' />
  <REGION_OWNERSHIPS region='trinidad_tobago' faction='pirates' />
  <REGION_OWNERSHIPS region='carolinas' faction='thirteen_colonies' />
  <REGION_OWNERSHIPS region='windward_islands' faction='france' />
  <REGION_OWNERSHIPS region='maine' faction='thirteen_colonies' />
  <REGION_OWNERSHIPS region='new_andalusia' faction='new_spain' />
  <REGION_OWNERSHIPS region='new_york' faction='thirteen_colonies' />
  <REGION_OWNERSHIPS region='guatemala' faction='new_spain' />
  <REGION_OWNERSHIPS region='leeward_islands' faction='pirates' />
  <REGION_OWNERSHIPS region='algonquin_territory' faction='iroquoi' />
  <REGION_OWNERSHIPS region='huron_territory' faction='huron' />
  <REGION_OWNERSHIPS region='florida' faction='spain' />
  <REGION_OWNERSHIPS region='new_spain' faction='new_spain' />
  <REGION_OWNERSHIPS region='labrador' faction='inuit' />
  <REGION_OWNERSHIPS region='maryland' faction='thirteen_colonies' />
  <REGION_OWNERSHIPS region='panama' faction='new_spain' />
  <REGION_OWNERSHIPS region='cuba' faction='spain' />
  <REGION_OWNERSHIPS region='new_france' faction='france' />
  <REGION_OWNERSHIPS region='pennsylvania' faction='thirteen_colonies' />
  <REGION_OWNERSHIPS region='georgia_usa' faction='cherokee' />
  <REGION_OWNERSHIPS region='newfoundland' faction='france' />
  <REGION_OWNERSHIPS region='bahamas' faction='britain' />
  <REGION_OWNERSHIPS region='cherokee_territory' faction='cherokee' />
  <REGION_OWNERSHIPS region='ontario' faction='france' />
  <REGION_OWNERSHIPS region='kaintuck_territory' faction='cherokee' />
  <REGION_OWNERSHIPS region='jamaica' faction='britain' />
  <REGION_OWNERSHIPS region='michigan_territory' faction='iroquoi' />
  <REGION_OWNERSHIPS region='new_mexico' faction='new_spain' />
  <REGION_OWNERSHIPS region='curacao' faction='netherlands' />
  <REGION_OWNERSHIPS region='new_grenada' faction='new_spain' />
  <REGION_OWNERSHIPS region='acadia' faction='france' />
 </ary>
</rec>


<ary version='0' type='AgentAbilities'>
 <AgentAbilities level='-1' ability='can_assassinate' extra='' />
 <AgentAbilities level='-1' ability='can_convert' extra='' />
 <AgentAbilities level='-1' ability='can_build_religious' extra='' />
 <AgentAbilities level='1' ability='can_build_fort' extra='command_land' />
 <AgentAbilities level='-1' ability='can_sabotage' extra='' />
 <AgentAbilities level='-1' ability='can_spy' extra='' />
 <AgentAbilities level='-1' ability='can_duel' extra='' />
 <AgentAbilities level='-1' ability='can_receive_duel' extra='' />
 <AgentAbilities level='-1' ability='can_research' extra='' />
 <AgentAbilities level='1' ability='can_attack_land' extra='command_land' />
 <AgentAbilities level='-1' ability='can_attack_naval' extra='' />
 <AgentAbilities level='-1' ability='can_sabotage_army' extra='' />
</ary>

<rec type='DIPLOMACY_RELATIONSHIPS_ARRAY'>
 <rec version='9' type='DIPLOMACY_RELATIONSHIP'>
  <i>583588928</i>
  <ary version='0' type='DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY'>
   <DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY a='0' b='0' c='0' e='0' d='false' f='false' />
   <DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY a='0' b='0' c='0' e='0' d='false' f='false' />
   <DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY a='0' b='0' c='0' e='0' d='false' f='false' />
   <DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY a='0' b='0' c='0' e='0' d='false' f='false' />
   <DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY a='-1' b='15' c='0' e='15' d='true' f='true' />
   <DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY a='0' b='0' c='0' e='0' d='false' f='false' />
   <DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY a='0' b='0' c='0' e='0' d='false' f='false' />
   <DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY a='0' b='0' c='0' e='0' d='false' f='false' />
   <DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY a='0' b='0' c='0' e='0' d='false' f='false' />
   <DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY a='0' b='0' c='0' e='0' d='false' f='false' />
   <DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY a='0' b='0' c='0' e='-15' d='false' f='true' />
   <DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY a='0' b='0' c='0' e='0' d='false' f='false' />
   <DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY a='0' b='0' c='0' e='0' d='false' f='false' />
   <DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY a='0' b='0' c='0' e='0' d='false' f='false' />
   <DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY a='0' b='0' c='0' e='0' d='false' f='false' />
   <DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY a='0' b='20' c='0' e='0' d='false' f='false' />
   <DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY a='0' b='-30' c='0' e='0' d='false' f='false' />
   <DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY a='0' b='0' c='0' e='0' d='false' f='false' />
   <DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY a='0' b='0' c='0' e='0' d='false' f='false' />
   <DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY a='0' b='0' c='0' e='0' d='false' f='false' />
   <DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY a='0' b='0' c='0' e='0' d='false' f='false' />
   <DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY a='0' b='0' c='0' e='0' d='false' f='false' />
  </array>
  <false />
  <i>0</i>
  <s>neutral</s>
  <i>0</i>
  <u>0</u>
  <i>0</i>
  <i>0</i>
  <i>0</i>
  <i>0</i>
  <i>0</i>
  <u>0</u>
  <u>0</u>
  <ary version='0' type='REGULAR_PAYMENTS' />
  <u>0</u>
  <u>0</u>
  <ary version='0' type='ALLIED_IN_WAR_AGAINST' />
  <i4_ary size='11'>0 0 0 0 0 0 0 0 0 0 0</i4_ary>
  <u>0</u>
  <s>neutral</s>
  <false />
  <false />
  <i>0</i>
 </rec>
</rec>
