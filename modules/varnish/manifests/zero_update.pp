# Zero-specific update stuff
class varnish::zero_update($site) {
    class { '::varnish::netmapper_update_common': }

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

    # Generate icinga alert if zerofetch has not been running successfully.
    # Warn after 4 hours, generate a critical alert after 24 hours.
    $check_args = '-w 14400 -c 86400 -d /var/netmapper/ -g .update-success'
    nrpe::monitor_service { 'zerofetch-freshness':
        description  => 'Freshness of zerofetch successful run file',
        nrpe_command => "/usr/lib/nagios/plugins/check-fresh-files-in-dir.py ${check_args}",
        require      => File['/usr/lib/nagios/plugins/check-fresh-files-in-dir.py'],
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Varnish',
    }

    file { '/etc/zerofetcher':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }

    file { '/etc/zerofetcher/zerofetcher.auth':
        owner     => 'netmap',
        group     => 'netmap',
        mode      => '0400',
        content   => secret('misc/zerofetcher.auth'),
        require   => File['/etc/zerofetcher'],
        show_diff => false,
    }

    $cmd = "/usr/share/varnish/zerofetch.py -s \"${site}\" -a /etc/zerofetcher/zerofetcher.auth -d /var/netmapper 2>&1 | logger -t zerofetch"

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

    rsyslog::conf { 'zerofetch':
        source   => 'puppet:///modules/varnish/zerofetch.rsyslog.conf',
    }

    # Rotate /var/log/zerofetch.log
    logrotate::conf { 'zerofetch':
        ensure => present,
        source => 'puppet:///modules/varnish/zerofetch-logrotate',
    }
}
