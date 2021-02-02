class role::ipsec ($hosts = undef) {
    $puppet_certname = $::fqdn

    # Host IPsec/strongswan alerts are now aggregated into an "Aggregate IPsec Tunnel Status" check which is driven by prometheus
    include profile::prometheus::ipsec_exporter

    file { '/usr/local/lib/nagios/plugins/check_strongswan':
        ensure => absent,
    }

    if $hosts != undef {
        $targets = $hosts
    }

    class { '::strongswan':
        puppet_certname => $puppet_certname,
        hosts           => $targets.filter |$target| { $target != '' },
    }
}
