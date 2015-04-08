class role::ipsec ($hosts = undef) {
    case $::realm {
        'labs': {
            $use_dnsmasq_server = hiera('use_dnsmasq', $::use_dnsmasq)
            if $use_dnsmasq_server {
                # If using the dnsmasq naming, scheme, we need
                # to use the unique ec2id rather than just the hostname.
                if($::ec2id == '') {
                    fail('Failed to fetch instance ID')
                }
                $puppet_certname = "${::ec2id}.${::domain}"
            } else {
                # With the new dns scheme, fqdn is unique and less
                #  confusing.
                $puppet_certname = $::fqdn
            }
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
        puppet_certname     => $puppet_certname,
        hosts               => $targets
    }
}
