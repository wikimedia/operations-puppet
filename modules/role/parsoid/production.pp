class role::parsoid::production {
    system::role { 'role::parsoid::production':
        description => 'Parsoid server'
    }

    include role::parsoid::common
    include standard
    include lvs::realserver
    include base::firewall

    package { 'parsoid/deploy':
        provider => 'trebuchet',
    }

    group { 'parsoid':
        ensure => present,
        name   => 'parsoid',
        system => true,
    }

    user { 'parsoid':
        gid        => 'parsoid',
        home       => '/var/lib/parsoid',
        managehome => true,
        system     => true,
    }

    file { '/var/lib/parsoid/deploy':
        ensure => link,
        target => '/srv/deployment/parsoid/deploy',
    }

    file { '/etc/init/parsoid.conf':
        ensure => present,
        owner  => root,
        group  => root,
        mode   => '0444',
        source => 'puppet:///modules/parsoid/parsoid.upstart',
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
        content => template('parsoid/parsoid.default.erb'),
        require => File['/var/log/parsoid'],
    }

    file { '/etc/logrotate.d/parsoid':
        ensure  => present,
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('parsoid/parsoid.logrotate.erb'),
    }

    cron { 'parsoid-hourly-logrot':
        ensure  => present,
        command => '/usr/sbin/logrotate /etc/logrotate.d/parsoid',
        user    => 'root',
        hour    => '*',
        minute  => '12',
        require => File['/etc/logrotate.d/parsoid'],
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
        description  => 'parsoid disk space',
        nrpe_command => '/usr/lib/nagios/plugins/check_disk -w 40% -c 3% -l -e',
        critical     => true,
    }

    # Monitor TCP Connection States
    diamond::collector { 'TcpConnStates':
        source => 'puppet:///modules/diamond/collector/tcpconnstates.py',
    }
}

