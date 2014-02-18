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

    file { '/usr/share/varnish/netmapper_update.sh':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => "puppet:///modules/${module_name}/netmapper_update.sh",
    }
}

define varnish::netmapper_update($url, $hour = '*', $minute = '*/5') {
    require 'varnish::netmapper_update_common'

    $cmd = "/usr/share/varnish/netmapper_update.sh \"${name}\" \"${url}\""

    exec { "netmapper_update_${name}_initial":
        user    => 'netmap',
        command => $cmd,
        creates => "/var/netmapper/${name}",
    }

    cron { "netmapper_update_${name}":
        user    => 'netmap',
        ensure  => absent, # temporary hack for zero issue...
        command => $cmd,
        hour    => $hour,
        minute  => $minute,
    }
}
