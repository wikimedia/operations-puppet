class role::ipsec ($hosts = undef) {
    case $::realm {
        'labs': {
            # labs nodes use their EC2 ID as their puppet cert name
            $puppet_certname = "${::ec2id}.${::domain}"
        }
        default: {
            $puppet_certname = $::fqdn
        }
    }

    if $hosts != undef {
        $targets = $hosts
    } else {
        # for 'left' nodes in cache sites, enumerate 'right' nodes in "main" sites
        if $::site == 'esams' or $::site == 'ulsfo' {
            $targets = concat(
                hiera('hosts_eqiad', []),
                hiera('hosts_codfw', [])
            )
        }
        # for 'left' nodes in "main" sites, enumerate 'right' nodes in cache sites
        if $::site == 'eqiad' or $::site == 'codfw' {
            $targets = concat(
                hiera('hosts_esams', []),
                hiera('hosts_ulsfo', [])
            )
        }
    }

    class { '::strongswan':
        puppet_certname => $puppet_certname,
        hosts           => $targets
    }
}
