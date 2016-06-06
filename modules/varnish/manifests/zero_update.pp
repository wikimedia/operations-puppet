# Zero-specific update stuff
class varnish::zero_update($site) {
    require 'varnish::netmapper_update_common'

    package { 'python-requests':
        ensure => installed;
    }

    file { '/usr/share/varnish/zerofetch.py':
        owner   => 'root',
        group   => 'root',
        mode    => '0555',
        source  => "puppet:///modules/${module_name}/zerofetch.py",
        require => Package['python-requests'],
    }

    file { '/etc/zerofetcher':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/etc/zerofetcher/zerofetcher.auth':
        owner   => 'netmap',
        group   => 'netmap',
        mode    => '0400',
        content => secret('misc/zerofetcher.auth'),
        require => File['/etc/zerofetcher'],
    }

    $cmd = "/usr/share/varnish/zerofetch.py -s \"${site}\" -a /etc/zerofetcher/zerofetcher.auth -d /var/netmapper"

    exec { 'zero_update_initial':
        user    => 'netmap',
        command => $cmd,
        creates => '/var/netmapper/proxies.json',
        require => File['/etc/zerofetcher/zerofetcher.auth'],
    }

    $m15 = fqdn_rand(15, 'fbba09c80d01946cb219d0c92bd5fb05')
    $minutes = [ $m15, ($m15 + 15), ($m15 + 30), ($m15 + 45) ]

    cron { 'zero_update':
        user    => 'netmap',
        command => $cmd,
        minute  => $minutes,
        hour    => '*',
        require => File['/etc/zerofetcher/zerofetcher.auth'],
    }
}
