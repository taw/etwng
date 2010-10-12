Note: This is old code, CRuby only, slow, no features etc.
      Might be useful due to simplicity anyway.



Not ready for an average Joe user.

Usage:
$ ./esf2xml <foo.esf >foo.xml
$ ./xml2esf <foo.xml >foo.esf

esf_types.rb is extra file used for schema compression.
Everything works just fine without it, except xml file is uglier.

At the moment mistakes in esf_types.rb crash conversion
instead of automatically falling back to basic style.

Some samples to give general feeling what this XML is like at the end of this file.

== XML structure ==

Every file starts with header like this:

<esf magic='43982 0 1232650587'>
 <node_names>
  <node_name name='root' />
  <node_name name='theatres_and_region_keys' />
  <node_name name='theatre' />
  <node_name name='region_keys' />
  <node_name name='theatres' />
  <node_name name='climate_map' />
  <node_name name='wind_map' />
  <node_name name='transition_areas' />
  ...
 </node_names>
 
It's only used for getting exact binary copies back and could 
in principle be regenerated.


Then you have basic types like:

 <str>628219853</str>
 <vec2 y='0.0' x='-760.0' />
 <false />
 <u4>1750</u4>
 <i4_ary size='11'>0 0 0 0 0 0 0 0 0 0 0</i4_ary>


uN - unsigned N-byte integer
iN - signed N-byte integer
false/true are booleans
bool - works as well
byte - 1-byte unsigned integer

str is utf-8 (converted to utf-16le in esf)
ascii is ascii (enforced only iso-8859-1 really)

flt/vec2/vec3 are single precision floats and their tuples

X_ary - array of X, size argument is to prevent accidental overwrites,
  some of these fields are fixed size, others are not.
bin are other array-like structures, printed in hex

Composites fields:

<array> - contains 0 or more <element>s of same kind
<element>/<record> - each contain some number of heterogenous fields.
Distinction between element and record is really only their context, and
I could probably get rid of it altogether to make is more sensible
for humans, but less sensible for Esf.

Some constant-schema records and elements get first level tags, like
  <REGION_OWNERSHIPS region='iroquois_territory' faction='iroquoi' />
which is really
  <element name="REGION_OWNERSHIPS">
    <str>iroquois_territory</str>
    <str>iroquoi</str>
  </element>

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
* what is flags="XX" for again ?
* Higher performance
* (some way to run it on Windows)
* Some numbers are not numbers but references or bitfields or something else,
  mark them differently.
* Things in XML in general shouldn't depend on position in non-trivial way,
  see DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY.

Both better quality XML and higher performance both require smarter architecture,
and need to move together.

== A few samples ==

<element name='REGION_OWNERSHIPS_BY_THEATRE'>
 <str>america</str>
 <array flags='0' name='REGION_OWNERSHIPS'>
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
 </array>
</element>


<array flags='0' name='AgentAbilities'>
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
</array>

<element name='DIPLOMACY_RELATIONSHIPS_ARRAY'>
 <record flags='9' name='DIPLOMACY_RELATIONSHIP'>
  <i4>583588928</i4>
  <array flags='0' name='DIPLOMACY_RELATIONSHIP_ATTITUDES_ARRAY'>
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
  <i4>0</i4>
  <str>neutral</str>
  <i4>0</i4>
  <u4>0</u4>
  <i4>0</i4>
  <i4>0</i4>
  <i4>0</i4>
  <i4>0</i4>
  <i4>0</i4>
  <u4>0</u4>
  <u4>0</u4>
  <array flags='0' name='REGULAR_PAYMENTS' />
  <u4>0</u4>
  <u4>0</u4>
  <array flags='0' name='ALLIED_IN_WAR_AGAINST' />
  <i4_ary size='11'>0 0 0 0 0 0 0 0 0 0 0</i4_ary>
  <u4>0</u4>
  <str>neutral</str>
  <false />
  <false />
  <i4>0</i4>
 </record>
</element>
