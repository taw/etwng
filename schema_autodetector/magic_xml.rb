# Needed for parsing
require 'rexml/parsers/baseparser'
# Needed for fetching XMLs from the Internet
require 'uri'
require 'net/http'

# FIXME: Make comment formatting RDoc-friendly. It's not always so now.

# In Ruby 2 Symbol will be a subclass of String, and
# this won't be needed any more. Before then...
class Symbol
    include Comparable
    def <=>(other)
        raise ArgumentError.new("comparison of #{self.class} with #{other.class} failed") unless other.is_a? Symbol
        to_s <=> other.to_s
    end
    
    alias_method :eqeqeq_before_magic_xml, :===
    def ===(*args, &blk)
        if args.size >= 1 and args[0].is_a? XML
            self == args[0].name
        else
            eqeqeq_before_magic_xml(*args, &blk)
        end
    end
end

class Hash
    alias_method :eqeqeq_before_magic_xml, :===
    def ===(*args, &blk)
        if args.size >= 1 and args[0].is_a? XML
            all?{|k,v| v === args[0][k]}
        else
            eqeqeq_before_magic_xml(*args, &blk)
        end
    end
end

class String
    # Escape string for output as XML text (< > &)
    def xml_escape
        replacements = {"<" => "&lt;", ">" => "&gt;", "&" => "&amp;" }
        gsub(/([<>&])/) { replacements[$1] }
    end
    # Escape characters for output as XML attribute values (< > & ' ")
    def xml_attr_escape
        replacements = {"<" => "&lt;", ">" => "&gt;", "&" => "&amp;", "\"" => "&quot;", "'" => "&apos;"}
        gsub(/([<>&\'\"])/) { replacements[$1] }
    end
    # Unescape entities
    # Supports:
    # * Full set of HTML-compatible named entities
    # * Decimal entities &#1234;
    # * Hex entities &#xA0b1;
    def xml_unescape(extra_entities=nil)
        @@xhtml_entity_replacements ||= {
            'nbsp' => 160,
            'iexcl' => 161,
            'cent' => 162,
            'pound' => 163,
            'curren' => 164,
            'yen' => 165,
            'brvbar' => 166,
            'sect' => 167,
            'uml' => 168,
            'copy' => 169,
            'ordf' => 170,
            'laquo' => 171,
            'not' => 172,
            'shy' => 173,
            'reg' => 174,
            'macr' => 175,
            'deg' => 176,
            'plusmn' => 177,
            'sup2' => 178,
            'sup3' => 179,
            'acute' => 180,
            'micro' => 181,
            'para' => 182,
            'middot' => 183,
            'cedil' => 184,
            'sup1' => 185,
            'ordm' => 186,
            'raquo' => 187,
            'frac14' => 188,
            'frac12' => 189,
            'frac34' => 190,
            'iquest' => 191,
            'Agrave' => 192,
            'Aacute' => 193,
            'Acirc' => 194,
            'Atilde' => 195,
            'Auml' => 196,
            'Aring' => 197,
            'AElig' => 198,
            'Ccedil' => 199,
            'Egrave' => 200,
            'Eacute' => 201,
            'Ecirc' => 202,
            'Euml' => 203,
            'Igrave' => 204,
            'Iacute' => 205,
            'Icirc' => 206,
            'Iuml' => 207,
            'ETH' => 208,
            'Ntilde' => 209,
            'Ograve' => 210,
            'Oacute' => 211,
            'Ocirc' => 212,
            'Otilde' => 213,
            'Ouml' => 214,
            'times' => 215,
            'Oslash' => 216,
            'Ugrave' => 217,
            'Uacute' => 218,
            'Ucirc' => 219,
            'Uuml' => 220,
            'Yacute' => 221,
            'THORN' => 222,
            'szlig' => 223,
            'agrave' => 224,
            'aacute' => 225,
            'acirc' => 226,
            'atilde' => 227,
            'auml' => 228,
            'aring' => 229,
            'aelig' => 230,
            'ccedil' => 231,
            'egrave' => 232,
            'eacute' => 233,
            'ecirc' => 234,
            'euml' => 235,
            'igrave' => 236,
            'iacute' => 237,
            'icirc' => 238,
            'iuml' => 239,
            'eth' => 240,
            'ntilde' => 241,
            'ograve' => 242,
            'oacute' => 243,
            'ocirc' => 244,
            'otilde' => 245,
            'ouml' => 246,
            'divide' => 247,
            'oslash' => 248,
            'ugrave' => 249,
            'uacute' => 250,
            'ucirc' => 251,
            'uuml' => 252,
            'yacute' => 253,
            'thorn' => 254,
            'yuml' => 255,
            'quot' => 34,
            'apos' => 39, # Wasn't present in the HTML entities set, but is defined in XML standard
            'amp' => 38,
            'lt' => 60,
            'gt' => 62,
            'OElig' => 338,
            'oelig' => 339,
            'Scaron' => 352,
            'scaron' => 353,
            'Yuml' => 376,
            'circ' => 710,
            'tilde' => 732,
            'ensp' => 8194,
            'emsp' => 8195,
            'thinsp' => 8201,
            'zwnj' => 8204,
            'zwj' => 8205,
            'lrm' => 8206,
            'rlm' => 8207,
            'ndash' => 8211,
            'mdash' => 8212,
            'lsquo' => 8216,
            'rsquo' => 8217,
            'sbquo' => 8218,
            'ldquo' => 8220,
            'rdquo' => 8221,
            'bdquo' => 8222,
            'dagger' => 8224,
            'Dagger' => 8225,
            'permil' => 8240,
            'lsaquo' => 8249,
            'rsaquo' => 8250,
            'euro' => 8364,
            'fnof' => 402,
            'Alpha' => 913,
            'Beta' => 914,
            'Gamma' => 915,
            'Delta' => 916,
            'Epsilon' => 917,
            'Zeta' => 918,
            'Eta' => 919,
            'Theta' => 920,
            'Iota' => 921,
            'Kappa' => 922,
            'Lambda' => 923,
            'Mu' => 924,
            'Nu' => 925,
            'Xi' => 926,
            'Omicron' => 927,
            'Pi' => 928,
            'Rho' => 929,
            'Sigma' => 931,
            'Tau' => 932,
            'Upsilon' => 933,
            'Phi' => 934,
            'Chi' => 935,
            'Psi' => 936,
            'Omega' => 937,
            'alpha' => 945,
            'beta' => 946,
            'gamma' => 947,
            'delta' => 948,
            'epsilon' => 949,
            'zeta' => 950,
            'eta' => 951,
            'theta' => 952,
            'iota' => 953,
            'kappa' => 954,
            'lambda' => 955,
            'mu' => 956,
            'nu' => 957,
            'xi' => 958,
            'omicron' => 959,
            'pi' => 960,
            'rho' => 961,
            'sigmaf' => 962,
            'sigma' => 963,
            'tau' => 964,
            'upsilon' => 965,
            'phi' => 966,
            'chi' => 967,
            'psi' => 968,
            'omega' => 969,
            'thetasym' => 977,
            'upsih' => 978,
            'piv' => 982,
            'bull' => 8226,
            'hellip' => 8230,
            'prime' => 8242,
            'Prime' => 8243,
            'oline' => 8254,
            'frasl' => 8260,
            'weierp' => 8472,
            'image' => 8465,
            'real' => 8476,
            'trade' => 8482,
            'alefsym' => 8501,
            'larr' => 8592,
            'uarr' => 8593,
            'rarr' => 8594,
            'darr' => 8595,
            'harr' => 8596,
            'crarr' => 8629,
            'lArr' => 8656,
            'uArr' => 8657,
            'rArr' => 8658,
            'dArr' => 8659,
            'hArr' => 8660,
            'forall' => 8704,
            'part' => 8706,
            'exist' => 8707,
            'empty' => 8709,
            'nabla' => 8711,
            'isin' => 8712,
            'notin' => 8713,
            'ni' => 8715,
            'prod' => 8719,
            'sum' => 8721,
            'minus' => 8722,
            'lowast' => 8727,
            'radic' => 8730,
            'prop' => 8733,
            'infin' => 8734,
            'ang' => 8736,
            'and' => 8743,
            'or' => 8744,
            'cap' => 8745,
            'cup' => 8746,
            'int' => 8747,
            'there4' => 8756,
            'sim' => 8764,
            'cong' => 8773,
            'asymp' => 8776,
            'ne' => 8800,
            'equiv' => 8801,
            'le' => 8804,
            'ge' => 8805,
            'sub' => 8834,
            'sup' => 8835,
            'nsub' => 8836,
            'sube' => 8838,
            'supe' => 8839,
            'oplus' => 8853,
            'otimes' => 8855,
            'perp' => 8869,
            'sdot' => 8901,
            'lceil' => 8968,
            'rceil' => 8969,
            'lfloor' => 8970,
            'rfloor' => 8971,
            'lang' => 9001,
            'rang' => 9002,
            'loz' => 9674,
            'spades' => 9824,
            'clubs' => 9827,
            'hearts' => 9829,
            'diams' => 9830,
        }
        gsub(/&(?:([a-zA-Z]+)|#([0-9]+)|#x([a-fA-F0-9]+));/) {
            if $1 then
                v = @@xhtml_entity_replacements[$1]
                # Nonstandard entity
                unless v
                    if extra_entities.is_a? Proc
                        v = extra_entities.call($1)
                    # Well, we expect a Hash here, but any container will do.
                    # As long as it's not a nil.
                    elsif extra_entities
                        v = extra_entities[$1]
                    end
                end
                raise "Unknown escape #{$1}" unless v
            elsif $2
                v = $2.to_i
            else
                v = $3.hex
            end
            # v can be a String or an Integer
            if v.is_a? String then v else [v].pack('U') end
        }
    end
    def xml_parse
        XML.parse(self)
    end
end

class File
    def xml_parse
        XML.parse(self)
    end
end

class Array
    # children of any element
    def children(*args, &blk)
        res = []
        each{|c|
            res += c.children(*args, &blk) if c.is_a? XML
        }
        res
    end
    # descendants of any element
    def descendants(*args, &blk)
        res = []
        each{|c|
            res += c.descendants(*args, &blk) if c.is_a? XML
        }
        res
    end
end

# Methods of Enumerable.
# It is not easy to design good methods, because XML
# is not really "a container", it just acts as one sometimes.
# Generally:
# * Methods that return nil should work
# * Methods that return an element should work
# * Methods that return a container should return XML container, not Array
# * Conversion methods should convert
#
# FIXME: Many methods use .dup, but do we want a shallow or a deep copy ?
class XML
    include Enumerable
    # Default any? is ok
    # Default all? is ok

    # Iterate over children, possibly with a selector
    def each(*selector, &blk)
        children(*selector, &blk)
        self
    end

    # Sort XML children of XML element.
    def sort_by(*args, &blk)
        self.dup{ @contents = @contents.select{|c| c.is_a? XML}.sort_by(*args, &blk) }
    end

    # Sort children of XML element.
    def children_sort_by(*args, &blk)
        self.dup{ @contents = @contents.sort_by(*args, &blk) }
    end

    # Sort children of XML element.
    #
    # Using sort is highly wrong, as XML (and XML-extras) is not even Comparable.
    # Use sort_by instead.
    #
    # Unless you define your own XML#<=> operator, or do something equally weird.
    def sort(*args, &blk)
        self.dup{ @contents = @contents.sort(*args, &blk) }
    end

    #collect/map
    #detect/find
    #each_cons
    #each_slice
    #each_with_index
    #to_a
    #entries
    #enum_cons
    #enum_slice
    #enum
    # grep
    # include?/member?
    # inject
    # max/min
    # max_by/min_by - Ruby 1.9
    # partition
    # reject
    # sort
    # sort_by
    # to_set
    # zip
    # And Enumerable::Enumerator-generating methods
end

# Class methods
class XML
    # XML.foo! == xml!(:foo)
    # XML.foo  == xml(:foo)
    def self.method_missing(meth, *args, &blk) 
        if meth.to_s =~ /^(.*)!$/
            xml!($1.to_sym, *args, &blk)
        else
            XML.new(meth, *args, &blk)
        end
    end

    # Read file and parse
    def self.from_file(file)
        file = File.open(file) if file.is_a? String
        parse(file)
    end

    # Fetch URL and parse
    # Supported:
    # http://.../
    # https://.../
    # file:foo.xml
    # string:<foo/>
    def self.from_url(url)
        if url =~ /^string:(.*)$/m
            parse($1)
        elsif url =~ /^file:(.*)$/m
            from_file($1)
        elsif url =~ /^http(s?):/
            ssl = ($1 == "s")
            # No, seriously - Ruby needs something better than net/http
            # Something that groks basic auth and queries and redirects automatically:
            # HTTP_LIBRARY.get_content("http://username:passwd/u.r.l/?query")
            # URI parsing must go inside the library, client programs
            # should have nothing to do with it

            # net/http is really inconvenient to use here
            u = URI.parse(url)
            # You're not seeing this:
            if u.query then
                path = u.path + "?" + u.query
            else
                path = u.path
            end
            req = Net::HTTP::Get.new(path)
            if u.userinfo
                username, passwd = u.userinfo.split(/:/,2)
                req.basic_auth username, passwd
            end
            if ssl
                # NOTE: You need libopenssl-ruby installed
                # if you want to use HTTPS. Ubuntu is broken
                # as it doesn't provide it in the default packages.
                require 'net/https'
                http = Net::HTTP.new(u.host, u.port)
                http.use_ssl = true
                http.verify_mode = OpenSSL::SSL::VERIFY_NONE
            else
                http = Net::HTTP.new(u.host, u.port)
            end
            
            res = http.start {|http| http.request(req) }
            # TODO: Throw a more meaningful exception
            parse(res.body)
        else
            raise "URL protocol #{url} not supported (http, https, file, string are supported)"
        end
    end

    # Like CDuce load_xml
    # The path can be:
    # * file handler
    # * URL (a string with :)
    # * file name (a string without :)
    def self.load(obj)
        if obj.is_a? String
            if obj.include? ":"
                from_url(obj)
            else
                from_file(obj)
            end
        else
            parse(obj)
        end
    end

    # Parse XML in mixed stream/tree mode
    # Basically the idea is that every time we get start element,
    # we ask the block what to do about it.
    # If it wants a tree below it, it should call e.tree
    # If a tree was requested, elements below the current one
    # are *not* processed. If it wasn't, they are.
    #
    # For example:
    #  <foo><bar/></foo><foo2/>
    #  yield <foo> ... </foo>
    #  .complete! called
    #  process <foo2> next
    #
    # But:
    #  <foo><bar/></foo><foo2/>
    #  yield <foo> ... </foo>
    #  .complete! not called
    #  process <bar> next
    #
    # FIXME: yielded values are not reusable for now
    # FIXME: make more object-oriented
    def self.parse_as_twigs(stream)
        parser = REXML::Parsers::BaseParser.new stream
        # We don't really need to keep the stack ;-)
        stack = []
        while true
            event = parser.pull
            case event[0]
            when :start_element
                # Now the evil part evil
                attrs = {}
                event[2].each{|k,v| attrs[k.to_sym] = v.xml_unescape}
                node = XML.new(event[1].to_sym, attrs, *event[3..-1])
                
                # I can't say it's superelegant
                class <<node
                    attr_accessor :do_complete
                    def complete!
                        if @do_complete
                            @do_complete.call
                            @do_complete = nil
                        end
                    end
                end
                node.do_complete = proc{
                    parse_subtree(node, parser)
                }

                yield(node)
                if node.do_complete
                    stack.push node
                    node.do_complete = nil # It's too late, complete! shouldn't do anything now
                end
            when :end_element
                stack.pop
            when :end_document
                return
            else
                # FIXME: Do the right thing.
                # For now, ignore *everything* else
                # This is totally incorrect, user might want to 
                # see text, comments and stuff like that anyway
            end
        end
    end
    
    # Basically it's a copy of self.parse, ugly ...
    def self.parse_subtree(start_node, parser)
        stack = [start_node]
        res = nil
        while true
            event = parser.pull
            case event[0]
            when :start_element
                attrs = {}
                event[2].each{|k,v| attrs[k.to_sym] = v.xml_unescape}
                stack << XML.new(event[1].to_sym, attrs, *event[3..-1])
                if stack.size == 1
                    res = stack[0] 
                else
                    stack[-2] << stack[-1]
                end
            when :end_element
                stack.pop
                return if stack == []
            # Needs unescaping
            when :text
                 # Ignore whitespace
                 if stack.size == 0
                     next if event[1] !~ /\S/
                     raise "Non-whitespace text out of document root"
                 end
                 stack[-1] << event[1].xml_unescape
            # CDATA is already unescaped
            when :cdata
                 if stack.size == 0
                     raise "CDATA out of the document root"
                 end
                 stack[-1] << event[1]
            when :end_document
                raise "Parse error: end_document inside a subtree, tags are not balanced"
            when :xmldecl,:start_doctype,:end_doctype,:elementdecl,:processing_instruction
                # Positivery ignore
            when :comment,:externalentity,:entity,:attlistdecl,:notationdecl
                # Ignore ???
                #print "Ignored XML event #{event[0]} when parsing\n"
            else
                # Huh ? What's that ?
                #print "Unknown XML event #{event[0]} when parsing\n"
            end
        end
        res

    end

    # Parse XML using REXML. Available options:
    # * :extra_entities => Proc or Hash (default = nil)
    # * :remove_pretty_printing => true/false (default = false)
    # * :comments => true/false (default = false)
    # * :pi => true/false (default = false)
    # * :normalize => true/false (default = false) - normalize
    # * :multiple_roots => true/false (default=false) - document
    #      can have any number of roots (instread of one).
    #      Return all in an array instead of root/nil.
    #      Also include non-elements (String/PI/Comment) in the return set !!!
    #
    # FIXME: :comments/:pi will break everything
    # if there are comments/PIs outside document root.
    # Now PIs are outside the document root more often than not,
    # so we're pretty much screwed here.
    #
    # FIXME: Integrate all kinds of parse, and make them support extra options
    #
    # FIXME: Benchmark normalize!
    #
    # FIXME: Benchmark dup-based Enumerable methods
    #
    # FIXME: Make it possible to include bogus XML_Document superparent,
    #        and to make it support out-of-root PIs/Comments
    def self.parse(stream, options={})
        extra_entities = options[:extra_entities]

        parser = REXML::Parsers::BaseParser.new stream
        stack = [[]]
        
        while true
            event = parser.pull
            case event[0]
            when :start_element
                attrs = {}
                event[2].each{|k,v| attrs[k.to_sym] = v.xml_unescape(extra_entities) }
                stack << XML.new(event[1].to_sym, attrs, event[3..-1])
                stack[-2] << stack[-1]
            when :end_element
                stack.pop
            # Needs unescaping
            when :text
                 e = event[1].xml_unescape(extra_entities)
                 # Either inside root or in multi-root mode
                 if stack.size > 1 or options[:multiple_roots]
                     stack[-1] << e
                 elsif event[1] !~ /\S/
                     # Ignore out-of-root whitespace in single-root mode
                 else
                     raise "Non-whitespace text out of document root (and not in multiroot mode): #{event[1]}"
                 end
            # CDATA is already unescaped
            when :cdata
                e = event[1]
                if stack.size > 1 or options[:multiple_roots]
                    stack[-1] << e
                else
                    raise "CDATA out of the document root"
                end
            when :comment
                next unless options[:comments]
                e = XML_Comment.new(event[1])
                if stack.size > 1 or options[:multiple_roots]
                    stack[-1] << e
                else
                    # FIXME: Ugly !
                    raise "Comments out of the document root"
                end
            when :processing_instruction
                # FIXME: Real PI node
                next unless options[:pi]
                e = XML_PI.new(event[1], event[2])
                if stack.size > 1 or options[:multiple_roots]
                    stack[-1] << e
                else
                    # FIXME: Ugly !
                    raise "Processing instruction out of the document root"
                end
            when :end_document
                break
            when :xmldecl,:start_doctype,:end_doctype,:elementdecl
                # Positivery ignore
            when :externalentity,:entity,:attlistdecl,:notationdecl
                # Ignore ???
                #print "Ignored XML event #{event[0]} when parsing\n"
            else
                # Huh ? What's that ?
                #print "Unknown XML event #{event[0]} when parsing\n"
            end
        end
        roots = stack[0]
        
        roots.each{|root| root.remove_pretty_printing!} if options[:remove_pretty_printing]
        # :remove_pretty_printing does :normalize anyway
        roots.each{|root| root.normalize!} if options[:normalize]
        if options[:multiple_roots]
            roots
        else
            roots[0]
        end
    end

    # Parse a sequence. Equivalent to XML.parse(stream, :multiple_roots => true).
    def self.parse_sequence(stream, options={})
        o = options.dup
        o[:multiple_roots] = true
        parse(stream, o)
    end

    # Renormalize a string containing XML document
    def self.renormalize(stream)
        parse(stream).to_s
    end

    # Renormalize a string containing a sequence of XML documents
    # and strings
    # XMLrenormalize_sequence("<hello   />, <world></world>!") =>
    # "<hello/>, <world/>!"
    def self.renormalize_sequence(stream)
        parse_sequence(stream).to_s
    end
end

# Instance methods (other than those of Enumerable)
class XML
    attr_accessor :name, :attrs, :contents

    # initialize can be run in many ways
    # * XML.new
    # * XML.new(:tag_symbol)
    # * XML.new(:tag_symbol, {attributes})
    # * XML.new(:tag_symbol, "children", "more", XML.new(...))
    # * XML.new(:tag_symbol, {attributes}, "and", "children")
    # * XML.new(:tag_symbol) { monadic code }
    # * XML.new(:tag_symbol, {attributes}) { monadic code }
    #
    # Or even:
    # * XML.new(:tag_symbol, "children") { and some monadic code }
    # * XML.new(:tag_symbol, {attributes}, "children") { and some monadic code }
    # But typically you won't be mixing these two style
    #
    # Attribute values can will be converted to strings
    def initialize(*args, &blk)
        @name     = nil
        @attrs    = {}
        @contents = []
        @name = args.shift if args.size != 0
        if args.size != 0 and args[0].is_a? Hash
            args.shift.each{|k,v|
                # Do automatic conversion here
                # This also assures that the hashes are *not* shared
                self[k] = v
            }
        end
        # Expand Arrays passed as arguments
        self << args
        # FIXME: We'd rather not have people say @name = :foo there :-)
        if blk
            instance_eval(&blk)
        end
    end

    # Convert to a well-formatted XML
    def to_s
        "<#{@name}" + @attrs.sort.map{|k,v| " #{k}='#{v.xml_attr_escape}'"}.join +
        if @contents.size == 0
            "/>"
        else
            ">" + @contents.map{|x| if x.is_a? String then x.xml_escape else x.to_s end}.join + "</#{name}>"
        end
    end

    # Convert to a well-formatted XML, but without children information.
    # This is a reasonable format for irb and debugging.
    # If you want to see a few levels of children, call inspect(2) and so on
    def inspect(include_children=0)
        "<#{@name}" + @attrs.sort.map{|k,v| " #{k}='#{v.xml_attr_escape}'"}.join +
        if @contents.size == 0
            "/>"
        elsif include_children == 0
            ">...</#{name}>"
        else
            ">" + @contents.map{|x| if x.is_a? String then x.xml_escape else x.inspect(include_children-1) end}.join + "</#{name}>"
        end
    end

    # Read attributes.
    # Also works with pseudoattributes:
    #  img[:@x] == img.child(:x).text # or nil if there isn't any.
    def [](key)
        if key.to_s[0] == ?@
            tag = key.to_s[1..-1].to_sym
            c = child(tag)
            if c
                c.text
            else
                nil
            end
        else
            @attrs[key]
        end
    end

    # Set attributes.
    # Value is automatically converted to String, so you can say:
    #  img[:x] = 200
    # Also works with pseudoattributes:
    #  foo[:@bar] = "x"
    def []=(key, value)
        if key.to_s[0] == ?@
            tag = key.to_s[1..-1].to_sym
            c = child(tag)
            if c
                c.contents = [value.to_s]
            else
                self << XML.new(tag, value.to_s)
            end
        else
            @attrs[key] = value.to_s
        end
    end

    # Add children.
    # Possible uses:
    # * Add single element
    #  self << xml(...)
    #  self << "foo"
    # Add nothing:
    #  self << nil  
    # Add multiple elements (also works recursively):
    #  self << [a, b, c] 
    #  self << [a, [b, c], d] 
    def <<(cnt)
        if cnt.nil?
            # skip
        elsif cnt.is_a? Array
            cnt.each{|elem| self << elem}
        else
            @contents << cnt
        end
        self
    end

    # Equality test, works as if XMLs were normalized, so:
    #  XML.new(:foo, "Hello, ", "world") == XML.new(:foo, "Hello, world")
    def ==(x)
        return false unless x.is_a? XML
        return false unless name == x.name and attrs == x.attrs
        # Now the hard part, strings can be split in different ways
        # empty string children are possible etc.
        self_i = 0
        othr_i = 0
        while self_i != contents.size or othr_i != x.contents.size
            # Ignore ""s
            if contents[self_i].is_a? String and contents[self_i] == ""
                self_i += 1
                next
            end
            if x.contents[othr_i].is_a? String and x.contents[othr_i] == ""
                othr_i += 1
                next
            end

            # If one is finished and the other contains non-empty elements,
            # they are not equal
            return false if self_i == contents.size or othr_i == x.contents.size

            # Are they both Strings ?
            # Strings can be divided in different ways, and calling normalize!
            # here would be rather expensive, so let's use this complicated
            # algorithm
            if contents[self_i].is_a? String and x.contents[othr_i].is_a? String
                a = contents[self_i]
                b = x.contents[othr_i]
                self_i += 1
                othr_i += 1
                while a != "" or b != ""
                    if a == b
                        a = ""
                        b = ""
                    elsif a.size > b.size and a[0, b.size] == b
                        a = a[b.size..-1]
                        if x.contents[othr_i].is_a? String
                            b = x.contents[othr_i]
                            othr_i += 1
                            next
                        end
                    elsif b.size > a.size and b[0, a.size] == a
                        b = b[a.size..-1]
                        if contents[self_i].is_a? String
                            a = contents[self_i]
                            self_i += 1
                            next
                        end
                    else
                        return false
                    end
                end
                next
            end

            # OK, so at least one of them is not a String.
            # Hopefully they're either both XMLs or one is an XML and the
            # other is a String. It is also possible that contents contains
            # something illegal, but we aren't catching that,
            # so xml(:foo, Garbage.new) is going to at least equal itself.
            # And we aren't, because xml(:foo, Garbage.new) == xml(:bar, Garbage.new)
            # is going to return an honest false, and incoherent sanity
            # check is worse than no sanity check.
            #
            # Oh yeah, they can be XML_PI or XML_Comment. In such case, this
            # is ok.
            return false unless contents[self_i] == x.contents[othr_i]
            self_i += 1
            othr_i += 1
        end
        return true
    end

    alias_method :real_method_missing, :method_missing
    # Define all foo!-methods for monadic interface, so you can write:
    # 
    def method_missing(meth, *args, &blk) 
        if meth.to_s =~ /^(.*)!$/
            self << XML.new($1.to_sym, *args, &blk)
        else
            real_method_missing(meth, *args, &blk)
        end
    end

    # Make monadic interface more "official"
    # * node.exec! { foo!; bar! }
    # is equivalent to
    # * node << xml(:foo) << xml(:bar)
    def exec!(&blk)
        instance_eval(&blk)
    end

    # Select a subtree
    # NOTE: Uses object_id of the start/end tags !
    # They have to be the same, not just identical !
    # <foo>0<a>1</a><b/><c/><d>2</d><e/>3</foo>.range(<a>1</a>, <d>2</d>)
    # returns
    # <foo><b/><c/></foo>
    # start and end and their descendants are not included in
    # the result tree.
    # Either start or end can be nil.
    # * If both start and end are nil, return whole tree.
    # * If start is nil, return subtree up to range_end.
    # * If start is not inside the tree, return nil.
    # * If end is nil, return subtree from start
    # * If end is not inside the tree, return subtree from start.
    # * If end is before or below start, or they're the same node, the result is unspecified.
    # * if end comes directly after start, or as first node when start==nil, return path reaching there.
    def range(range_start, range_end, end_reached_cb=nil)
        if range_start == nil
            result = XML.new(name, attrs)
        else
            result = nil
        end
        @contents.each {|c|
            # end reached !
            if range_end and c.object_id == range_end.object_id
                end_reached_cb.call if end_reached_cb
                break
            end
            # start reached !
            if range_start and c.object_id == range_start.object_id
                result = XML.new(name, attrs)
                next
            end
            if result # We already started
                if c.is_a? XML
                    break_me = false
                    result.add! c.range(nil, range_end, lambda{ break_me = true })
                    if break_me
                        end_reached_cb.call if end_reached_cb
                        break
                    end
                else # String/XML_PI/XML_Comment
                    result.add! c
                end
            else
                # Strings/XML_PI/XML_Comment obviously cannot start a range
                if c.is_a? XML
                    break_me = false
                    r = c.range(range_start, range_end, lambda{ break_me = true })
                    if r
                        # start reached !
                        result = XML.new(name, attrs, r)
                    end
                    if break_me
                        # end reached !
                        end_reached_cb.call if end_reached_cb
                        break
                    end
                end
            end
        }
        return result
    end

    # XML#subsequence is similar to XML#range, but instead of
    # trimmed subtree in returns a list of elements
    # The same elements are included in both cases, but here
    # we do not include any parents !
    #
    # <foo><a/><b/><c/></foo>.range(a,c) => <foo><b/></foo>
    # <foo><a/><b/><c/></foo>.subsequence(a,c) => <b/>
    #
    # <foo><a><a1/></a><b/><c/></foo>.range(a1,c) => <foo><a/><b/></foo> # Does <a/> make sense ?
    # <foo><a><a1/></a><b/><c/></foo>.subsequence(a1,c) => <b/>
    #
    # <foo><a><a1/><a2/></a><b/><c/></foo>.range(a1,c) => <foo><a><a2/></a><b/></foo>
    # <foo><a><a1/><a2/></a><b/><c/></foo>.subsequence(a1,c) => <a2/><b/>
    #
    # And we return [], not nil if nothing matches
    def subsequence(range_start, range_end, start_seen_cb=nil, end_seen_cb=nil)
        result = []
        start_seen = range_start.nil?
        @contents.each{|c|
            if range_end and range_end.object_id == c.object_id
                end_seen_cb.call if end_seen_cb
                break 
            end
            if range_start and range_start.object_id == c.object_id
                start_seen = true
                start_seen_cb.call if start_seen_cb
                next
            end
            if start_seen
                if c.is_a? XML
                    break_me = false
                    result += c.subsequence(nil, range_end, nil, lambda{break_me=true})
                    break if break_me
                else # String/XML_PI/XML_Comment
                    result << c
                end
            else
                # String/XML_PI/XML_Comment cannot start a subsequence
                if c.is_a? XML
                    break_me = false
                    result += c.subsequence(range_start, range_end, lambda{start_seen=true}, lambda{break_me=true})
                    break if break_me
                end
            end
        }
        # Include starting tag if it was right from the range_start
        # Otherwise, return just the raw sequence
        result = [XML.new(@name, @attrs, result)] if range_start == nil
        return result
    end

    # =~ for a few reasonable patterns
    def =~(pattern)
        if pattern.is_a? Symbol
            @name == pattern
        elsif pattern.is_a? Regexp
            rv = text =~ pattern
        else # Hash, Pattern_any, Pattern_all
            pattern === self
        end
    end
    
    # Get rid of pretty-printing whitespace. Also normalizes the XML.
    def remove_pretty_printing!(exceptions=nil)
        normalize!
        real_remove_pretty_printing!(exceptions)
        normalize!
    end

    # normalize! is already recursive, so only one call at top level is needed.
    # This helper method lets us avoid extra calls to normalize!.
    def real_remove_pretty_printing!(exceptions=nil)
        return if exceptions and exceptions.include? @name
        each{|c|
            if c.is_a? String
                c.sub!(/^\s+/, "")
                c.sub!(/\s+$/, "")
                c.gsub!(/\s+/, " ")
            elsif c.is_a? XML_PI or c.is_a? XML_Comment
            else
                c.real_remove_pretty_printing!(exceptions)
            end
        }
    end

    protected :real_remove_pretty_printing!

    # Add pretty-printing whitespace. Also normalizes the XML.
    def add_pretty_printing!
        normalize!
        real_add_pretty_printing!
        normalize!
    end
    
    def real_add_pretty_printing!(indent = "")
        return if @contents.empty?
        each{|c|
            if c.is_a? XML
                c.real_add_pretty_printing!(indent+"  ")
            elsif c.is_a? String
                c.gsub!(/\n\s*/, "\n#{indent}  ")
            end
        }
        @contents = @contents.inject([]){|children, c| children + ["\n#{indent}  ", c]}+["\n#{indent}"]
    end

    protected :real_add_pretty_printing!

    alias_method :raw_dup, :dup
    # This is not a trivial method - first it does a *deep* copy,
    # second it takes a block which is instance_eval'ed,
    # so you can do things like:
    # * node.dup{ @name = :foo }
    # * node.dup{ self[:color] = "blue" }
    def dup(&blk)
        new_obj = self.raw_dup
        # Attr values stay shared - ugly
        new_obj.attrs = new_obj.attrs.dup
        new_obj.contents = new_obj.contents.map{|c| c.dup}
        
        new_obj.instance_eval(&blk) if blk
        return new_obj
    end


    # Add some String children (all attributes get to_s'ed)
    def text!(*args)
        args.each{|s| self << s.to_s}
    end
    # Add XML child
    def xml!(*args, &blk)
        @contents << XML.new(*args, &blk)
    end

    alias_method :add!, :<<
    
    # Normalization means joining strings
    # and getting rid of ""s, recursively
    def normalize!
        new_contents = []
        @contents.each{|c|
            if c.is_a? String
                next if c == ""
                if new_contents[-1].is_a? String
                    new_contents[-1] += c
                    next
                end
            else
                c.normalize!
            end
            new_contents.push c
        }
        @contents = new_contents
    end

    # Return text below the node, stripping all XML tags,
    # "<foo>Hello, <bar>world</bar>!</foo>".xml_parse.text
    # returns "Hello, world!"
    def text
        res = ""
        @contents.each{|c|
            if c.is_a? XML
                res << c.text
            elsif c.is_a? String
                res << c
            end # Ignore XML_PI/XML_Comment
        }
        res
    end

    # Equivalent to node.children(pat, *rest)[0]
    # Returns nil if there aren't any matching children
    def child(pat=nil, *rest)
        children(pat, *rest) {|c|
            return c
        }
        return nil
    end

    # Equivalent to node.descendants(pat, *rest)[0]
    # Returns nil if there aren't any matching descendants
    def descendant(pat=nil, *rest)
        descendants(pat, *rest) {|c|
            return c
        }
        return nil
    end

    # XML#children(pattern, more_patterns)
    # Return all children of a node with tags matching tag.
    # Also:
    # * children(:a, :b) == children(:a).children(:b)
    # * children(:a, :*, :c) == children(:a).descendants(:c)
    def children(pat=nil, *rest, &blk)
        return descendants(*rest, &blk) if pat == :*
        res = []
        @contents.each{|c|
            if pat.nil? or pat === c
                if rest == []
                    res << c
                    yield c if block_given?
                else
                    res += c.children(*rest, &blk)
                end
            end
        }
        res
    end
    
    # * XML#descendants
    # * XML#descendants(pattern)
    # * XML#descendants(pattern, more_patterns)
    #
    # Return all descendants of a node matching the pattern.
    # If pattern==nil, simply return all descendants.
    # Optionally run a block on each of them if a block was given.
    # If pattern==nil, also match Strings !
    def descendants(pat=nil, *rest, &blk)
        res = []
        @contents.each{|c|
            if pat.nil? or pat === c
                if rest == []
                    res << c
                    yield c if block_given?
                else
                    res += c.children(*rest, &blk)
                end
            end
            if c.is_a? XML
                res += c.descendants(pat, *rest, &blk)
            end
        }
        res
    end
    
    # Change elements based on pattern
    def deep_map(pat, &blk)
        if self =~ pat
            yield self
        else
            r = XML.new(self.name, self.attrs)
            each{|c|
                if c.is_a? XML
                    r << c.deep_map(pat, &blk)
                else
                    r << c
                end
            }
            r
        end
    end

    # FIXME: do we want a shallow or a deep copy here ?
    # Map children, but leave the name/attributes
    def map(pat=nil)
        r = XML.new(self.name, self.attrs)
        each{|c|
            if !pat || c =~ pat
                r << yield(c)
            else
                r << c
            end
        }
        r
    end
end

# FIXME: Is this even sane ?
# * What about escaping and all that stuff ?
# * Rest of the code assumes that everything is either XML or String
class XML_PI
    def initialize(c, t)
        @c = c
        @t = t
    end
    def to_s
        "<?#{@c}#{@t}?>"
    end
end

# FIXME: Is this even sane ?
# * What about escaping and all that stuff ?
# * Rest of the code assumes that everything is either XML or String
# * There are some limitations on where one can put -s in the comment. Do not overdo.
class XML_Comment
    def initialize(c)
        @c = c
    end
    def to_s
        "<!--#{@c}-->"
    end
end

# Syntactic sugar for XML.new
def xml(*args, &blk)
    XML.new(*args, &blk)
end

# xml! in XML { ... } - context adds node to parent
# xml! in main context prints the argument (and returns it anyway)
def xml!(*args, &blk)
    node = xml(*args, &blk)
    print node
    node
end

# Perl 6 is supposed to have native support for something like that.
# Constructor takes multiple patterns. The object matches if they all match.
#
# Usage:
#  case foo
#  when all(:foo, {:color => 'blue'}, /Hello/)
#       print foo
#  end
class Patterns_all
    def initialize(*patterns)
        @patterns = patterns
    end
    def ===(obj)
        @patterns.all?{|p| p === obj}
    end
end

def all(*patterns)
    Patterns_all.new(*patterns)
end

# Perl 6 is supposed to have native support for something like that.
# Constructor takes multiple patterns. The object matches if they all match.
#
# Usage:
#  case foo
#  when all(:foo, any({:color => 'blue'}, {:color => 'red'}), /Hello/)
#       print foo
#  end
class Patterns_any
    def initialize(*patterns)
        @patterns = patterns
    end
    def ===(obj)
        @patterns.any?{|p| p === obj}
    end
end

def any(*patterns)
    Patterns_any.new(*patterns)
end
