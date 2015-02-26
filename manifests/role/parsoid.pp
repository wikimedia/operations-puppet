# vim: set ts=4 et sw=4:

@monitoring::group { 'parsoid_eqiad': description => 'eqiad parsoid servers' }

class role::parsoid {
    system::role { 'role::parsoid':
        description => 'Parsoid server'
    }

    include standard
    if $::realm != 'labs' {
        include admin
    }
    include lvs::realserver
    include base::firewall

    package { [
        'nodejs',
        'npm',
        'build-essential',
        ]: ensure => present,
    }

    file { '/var/lib/parsoid':
        ensure => directory,
        owner  => parsoid,
        group  => wikidev,
        mode   => '2775',
    }

    file { '/usr/bin/parsoid':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => '0555',
        source => 'puppet:///files/misc/parsoid',
    }

    ferm::service { 'parsoid':
        proto => 'tcp',
        port  => '8000',
    }

    package { 'parsoid/deploy':
        provider => 'trebuchet',
    }

    group { 'parsoid':
        ensure => present,
        name   => 'parsoid',
        system => true,
    }

    user { 'parsoid':
        gid           => 'parsoid',
        home          => '/var/lib/parsoid',
        managehome    => true,
        system        => true,
    }

    file { '/var/lib/parsoid/deploy':
        ensure => link,
        target => '/srv/deployment/parsoid/deploy',
    }

    file { '/etc/init/parsoid.conf':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        source  => 'puppet:///files/misc/parsoid.upstart',
    }
    file { '/var/log/parsoid':
        ensure => directory,
        owner  => parsoid,
        group  => parsoid,
        mode   => '0775',
    }

    $parsoid_log_file = '/var/log/parsoid/parsoid.log'
    #TODO: Should we explicitly set this to '/srv/deployment/parsoid/deploy/node_modules'
    #just like beta labs
    $parsoid_node_path = '/var/lib/parsoid/deploy/node_modules'
    $parsoid_settings_file = '/srv/deployment/parsoid/deploy/conf/wmf/localsettings.js'
    $parsoid_base_path = '/var/lib/parsoid/deploy/src'

    #TODO: Duplication of code from beta class, deduplicate somehow
    file { '/etc/default/parsoid':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('misc/parsoid.default.erb'),
        require => File['/var/log/parsoid'],
    }

    file { '/etc/logrotate.d/parsoid':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('misc/parsoid.logrotate.erb'),
    }

    cron { 'parsoid-hourly-logrot':
        ensure   => present,
        command  => '/usr/sbin/logrotate /etc/logrotate.d/parsoid',
        user     => 'root',
        hour     => '*',
        minute   => '12',
        require  => File['/etc/logrotate.d/parsoid'],
    }

    service { 'parsoid':
        ensure     => running,
        hasstatus  => true,
        hasrestart => true,
        provider   => 'upstart',
        subscribe  => [
            File['/etc/default/parsoid'],
            File['/etc/init/parsoid.conf'],
        ],
        require    => Package['parsoid/deploy'],
    }

    monitoring::service { 'parsoid':
        description   => 'Parsoid',
        check_command => 'check_http_on_port!8000',
    }
    # until logging is handled differently, rt 6851
    nrpe::monitor_service { 'parsoid_disk_space':
        description   => 'parsoid disk space',
        nrpe_command  => '/usr/lib/nagios/plugins/check_disk -w 40% -c 3% -l -e',
        critical      => true,
    }
}
