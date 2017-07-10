class profile::puppetmaster::labsenc() {
    require_package('python3-yaml', 'python3-ldap3')

    include ldap::yamlcreds

    file { '/etc/puppet-enc.yaml':
        content => ordered_yaml({
            host => hiera('labs_puppet_master'),
        }),
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
    }

    file { '/usr/local/bin/puppet-enc':
        source => 'puppet:///modules/role/labs/puppet-enc.py',
        mode   => '0555',
        owner  => 'root',
        group  => 'root',
    }
}
