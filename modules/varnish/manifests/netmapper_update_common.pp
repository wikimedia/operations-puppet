# basic infrastructure for netmapper json files
class varnish::netmapper_update_common {
    group { 'netmap':
        ensure => present,
    }

    user { 'netmap':
        home       => '/var/netmapper',
        gid        => 'netmap',
        system     => true,
        managehome => false,
        shell      => '/bin/false',
        require    => Group['netmap'],
    }

    file { '/var/netmapper':
        ensure  => directory,
        owner   => 'netmap',
        group   => 'netmap',
        require => User['netmap'],
        mode    => '0755',
    }
}

