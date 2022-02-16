class profile::openstack::base::puppetmaster::enc_client (
    Stdlib::HTTPUrl $api_endpoint = lookup('profile::openstack::base::puppetmaster::enc_client::api_endpoint'),
) {
    ensure_packages([
        'python3-requests',
        'python3-yaml',
    ])

    file { '/etc/puppet-enc.yaml':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => to_yaml({
            api_endpoint => $api_endpoint,
        }),
    }

    file { '/usr/local/bin/puppet-enc':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/openstack/base/puppetmaster/enc_client/puppet_enc.py',
    }
}
