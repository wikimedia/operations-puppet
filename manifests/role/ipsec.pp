class role::ipsec {
    case $::realm {
        'labs': {
            # openstack
            $fqdn_pem = "${ec2_instance_id}.${domain}.pem"
        }
        default: {
            $fqdn_pem = "${fqdn}.pem"
        }
    }

    # used in template to enumerate hosts
    # we should probably use hiera instead
    require role::cache::configuration

    class { '::strongswan':
        fqdn_pem     => $fqdn_pem,
    }
}
