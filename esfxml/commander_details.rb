module CommanderDetails
  # Based on factions db table and data from actual startpos.esf
  # They don't quite agree with each other
  # In the worst case, /XXX fallback is always supported
  NamesByFaction = {
    "afghanistan" => "persian",
    "american_rebels" => "english",
    "amerind_rebels" => "native_american",
    "austria" => "german_catholic",
    "austrian_rebels" => "german_catholic",
    "barbary_rebels" => "ottoman",
    "barbary_states" => "ottoman",
    "bavaria" => "german_catholic",
    "britain" => "english",
    "british_rebels" => "english",
    "british_settler_rebels" => "english",
    "chechenya_dagestan" => "persian",
    "cherokee" => "native_american",
    "cherokee_playable" => "native_american",
    "colombia" => "spanish",
    "cossack_rebels" => "slavonic_general",
    "courland" => "prussian",
    "crimean_khanate" => "muslim_general",
    "denmark" => "swedish",
    "dutch_rebels" => "dutch",
    "european_settler_rebels" => "english",
    "france" => "french",
    "french_rebels" => "french",
    "french_settler_rebels" => "french",
    "genoa" => "italian",
    "georgia" => "slavonic_general",
    "greece" => "greek",
    "greek_rebels" => "greek",
    "hannover" => "german_catholic",
    "hessen" => "german_catholic",
    "holstein_gottorp" => "german_catholic",
    "hungary" => "slavonic_general",
    "huron" => "native_american",
    "huron_playable" => "native_american",
    "india_settler_rebels" => "indian_hindu",
    "inuit" => "native_american",
    "ireland" => "english",
    "iroquoi" => "native_american",
    "iroquoi_playable" => "native_american",
    "italian_rebels" => "italian",
    "khanate_khiva" => "ottoman",
    "knights_stjohn" => "italian",
    "louisiana" => "french",
    "mamelukes" => "ottoman",
    "maratha" => "indian_hindu",
    "maratha_rebels" => "indian_hindu",
    "mecklenburg" => "german_catholic",
    "mexico" => "spanish",
    "middle_east_settler_rebels" => "ottoman",
    "morocco" => "muslim_general",
    "mughal" => "mughal",
    "mughal_rebels" => "mughal",
    "mysore" => "indian_hindu",
    "naples_sicily" => "italian",
    "netherlands" => "dutch",
    "new_spain" => "spanish",
    "norway" => "english",
    "ottoman_rebels" => "ottoman",
    "ottomans" => "ottoman",
    "papal_states" => "italian",
    "persian_rebels" => "persian",
    "piedmont_savoy" => "italian",
    "pirates" => "pirates",
    "plains" => "native_american",
    "plains_playable" => "native_american",
    "poland_lithuania" => "polish",
    "portugal" => "portuguese",
    "portugese_rebels" => "portuguese",
    "powhatan" => "native_american",
    "prussia" => "prussian",
    "prussian_rebels" => "prussian",
    "pueblo" => "native_american",
    "pueblo_playable" => "native_american",
    "punjab" => "indian_hindu",
    "quebec" => "french",
    "russia" => "slavonic_general",
    "safavids" => "persian",
    "saxony" => "german_catholic",
    "scandinavian_rebels" => "swedish",
    "scotland" => "english",
    "sikh_rebels" => "indian_hindu",
    "slavic_rebels" => "slavonic_general",
    "spain" => "spanish",
    "spanish_rebels" => "spanish",
    "spanish_settler_rebels" => "spanish",
    "sweden" => "swedish",
    "swiss_confederation" => "german_catholic",
    "thirteen_colonies" => "english",
    "tuscany" => "italian",
    "united_states" => "english",
    "venice" => "italian",
    "virginia" => "english",
    "virginia_colonists" => "english",
    "westphalia" => "german_catholic",
    "wurttemberg" => "german_catholic",
  }

  def self.parse(fnam, lnam, faction)
    return nil if [fnam, lnam, faction].any?{|x| x =~ /\s|\//}
    lnam = nil if lnam == ""
    return nil if fnam == ""
    return nil if faction == ""
    names = [fnam, lnam].compact
    
    nnn = "names_name_names_"
    return nil if names.all?{|n| n[0, nnn.size] == nnn.size}
    names = names.map{|n| n[nnn.size..-1]}

    faction_prefix = "#{faction}/-"
    NamesByFaction.values.uniq.each do |nameset|
      next unless names.all?{|n| n[0, nameset.size] == nameset}
      names = names.map{|n| n[nameset.size..-1]}
      if NamesByFaction[faction] == nameset
        faction_prefix = faction
      else
        faction_prefix = "#{faction}/#{nameset}"
      end
      break
    end

    [faction_prefix, *names].join(" ")
  end

  def self.recreate(str)
    faction, *names = str.strip.sub(%r[\s*/\s*], "/").split(/\s+/)
    raise "Expected forename or forename+surname" unless names.size.between?(1, 2)
    faction, nameset = faction.split("/", 2)
    if nameset == "-"
      prefix = ""
    elsif nameset.nil?
      prefix = NamesByFaction[faction]
    else
      prefix = nameset
    end
    names = names.map{|n| "names_name_names_#{prefix}#{n}"}
    [names[0], names[1] || "", faction]
  end
end
