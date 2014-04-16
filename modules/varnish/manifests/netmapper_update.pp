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

# Zero-specific update stuff
class varnish::zero_update($site, $authfile, $hour = '*', $minute = '*/5') {
    require 'varnish::netmapper_update_common'

    package { 'python-requests': ensure => installed; }

    file { '/usr/share/varnish/zerofetch.py':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => "puppet:///modules/${module_name}/zerofetch.py",
        require => Package["python-requests"],
    }

    $cmd = "/usr/share/varnish/zerofetch.py -s \"${site}\" -a \"${authfile}\" -d /var/netmapper"

    exec { "zero_update_initial":
        user    => 'netmap',
        command => $cmd,
        creates => "/var/netmapper/proxies.json",
    }

    cron { "zero_update":
        user    => 'netmap',
        command => $cmd,
        hour    => $hour,
        minute  => $minute,
    }
}
