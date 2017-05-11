# lvs/configuration.pp

class lvs::pybal_configuration (
    $bgp = hiera('lvs::pybal_configuration::bgp', 'yes'),
) {
    $pybal = {
        'bgp' => $bgp,
        'bgp-peer-address' => $::hostname ? {
            /^lvs100[1-3]$/ => '208.80.154.196', # cr1-eqiad
            /^lvs100[4-6]$/ => '208.80.154.197', # cr2-eqiad
            /^lvs100[789]$/ => '208.80.154.196', # cr1-eqiad
            /^lvs101[012]$/ => '208.80.154.197', # cr2-eqiad
            /^lvs200[1-3]$/ => '208.80.153.192', # cr1-codfw
            /^lvs200[4-6]$/ => '208.80.153.193', # cr2-codfw
            /^lvs300[12]$/  => '91.198.174.244',  # cr2-esams
            /^lvs300[34]$/  => '91.198.174.245',  # cr1-esams
            /^lvs400[12]$/  => '198.35.26.192',   # cr1-ulsfo
            /^lvs400[34]$/  => '198.35.26.193',   # cr2-ulsfo
            default         => '(unspecified)'
            },
        'bgp-nexthop-ipv4' => $facts['ipaddress'],
        'bgp-nexthop-ipv6' => inline_template("<%= require 'ipaddr'; (IPAddr.new(@ipaddress6).mask(64) | IPAddr.new(\"::\" + @ipaddress.gsub('.', ':'))).to_s() %>"),
        'instrumentation' => 'yes',
    }
}
