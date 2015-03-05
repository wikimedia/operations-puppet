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
        # determine site from domain name
        case $::domain {
            'eqiad.wmnet':         { $site = 'eqiad' }
            'codfw.wmnet':         { $site = 'codfw' }
            'esams.wmnet':         { $site = 'esams' }
            'esams.wikimedia.org': { $site = 'esams' }
            'ulsfo.wmnet':         { $site = 'ulsfo' }
        }

        # determine cache type based on whether it contains the local node
        if $::fqdn in hiera("text_${site}", "")   { $cachetype = "text" }
        if $::fqdn in hiera("bits_${site}", "")   { $cachetype = "bits" }
        if $::fqdn in hiera("upload_${site}", "") { $cachetype = "upload" }
        if $::fqdn in hiera("mobile_${site}", "") { $cachetype = "mobile" }

        # enumerate hosts of the same cache type in other sites
        if $site == 'esams' or $site == 'ulsfo' {
            $targets = concat(
                hiera("${cachetype}_eqiad", []),
                hiera("${cachetype}_codfw", [])
            )
        }
        if $site == 'eqiad' or $site == 'codfw' {
            $targets = concat(
                hiera("${cachetype}_esams", []),
                hiera("${cachetype}_ulsfo", [])
            )
        }
    }

    class { '::strongswan':
        puppet_certname     => $puppet_certname,
        hosts               => $targets
    }
}
