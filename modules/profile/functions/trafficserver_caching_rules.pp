function profile::trafficserver_caching_rules(Hash $req_handling, Hash $alternate_domains, Array[Trafficserver::Mapping_rule] $mapping_rules) >> Array[Trafficserver::Caching_rule] {
    $caching_rules = ($req_handling + $alternate_domains).map |$hostname, $entry| {
        if $entry['caching'] != 'normal' {
            # Build the list of remap rules for this hostname
            $remap_rule = $mapping_rules.filter |$idx, $rule| {
                $rule['target'].match("https?:\\/\\/${hostname}") != undef
            }

            if length($remap_rule) == 0 {
                # There should be at least one remap rule for each entry in
                # cache::req_handling and cache::alternate_domains
                fail("No rule found for ${hostname} in profile::trafficserver::backend::mapping_rules")
            }

            $remap_rule.map |$idx, $rule| {
                if $rule['replacement'] !~ /https?:\/\/([^\/:]+)/ {
                    fail("${rule['replacement']} is not a valid URL")
                } else {
                    # Origin server hostname found. Build a caching rule for it.
                    {
                        primary_destination => 'dest_host',
                        value => $1,
                        action => 'never-cache',
                    }
                }
            }
        }
    }

    flatten($caching_rules).filter |$rule| { $rule != undef }
}
