class profile::logster_alarm {

    file{ '/etc/logster':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
    }

    file{ '/etc/logster/badpass':
        ensure => 'file',
        owner  => 'root',
        group  => 'root',
    }

    file{ '/srv/security':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
    }

    file{ '/srv/security/logs':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
    }

    file{ '/srv/security/logs/archive':
        ensure => 'directory',
        owner  => 'root',
        group  => 'root',
        mode   => '0655',
    }

    file{ '/etc/logrotate.d/security-mw':
        source => 'puppet:///modules/profile/logster_alarm/security.logrotate',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    logster::job{'badpass':
        parser          => 'AlarmCounterLogster',
        logfile         => '/srv/mw-log/csp-report-only.log',
        logster_options => "--parser-option='-a /etc/logster/csp -s /srv/security/logs/csp-report-only.log -n CSP -e logsteralarms@wikimedia.org'",
    }
}
