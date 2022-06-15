class profile::logster_alarm {

    ensure_packages(['python-yaml',
                    'python-ipaddress'])

    file{ '/etc/logster':
        ensure => 'directory',
        owner  => 'root',
        group  => 'deployment',
        mode   => '0675',
    }

    file{ '/etc/logster/badpass-priv.yaml':
        ensure => 'file',
        owner  => 'root',
        group  => 'deployment',
        mode   => '0675',
    }

    file{ '/etc/logster/csp.yaml':
        ensure => 'file',
        owner  => 'root',
        group  => 'deployment',
        mode   => '0675',
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

    file{ '/usr/lib/python2.7/dist-packages/logster/parsers/AlarmCounterLogster.py':
        source => 'puppet:///modules/profile/logster_alarm/AlarmCounterLogster.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0644',
    }

    logster::job{'csp':
        ensure          => absent,
        parser          => '--output stdout AlarmCounterLogster',
        logfile         => '/srv/mw-log/csp-report-only.log',
        logster_options => "--parser-option='-a /etc/logster/csp.yaml -s /srv/security/logs/csp-report-only.log -n CSP -e security-admin-feed@lists.wikimedia.org,logsteralarms@wikimedia.org'",
    }

    logster::job{'badpass_priv':
        ensure          => absent,
        parser          => '--output stdout AlarmCounterLogster',
        logfile         => '/srv/mw-log/badpass-priv.log',
        logster_options => "--parser-option='-a /etc/logster/badpass-priv.yaml -s /srv/security/logs/badpass-priv.log -n badpass-priv -e security-admin-feed@lists.wikimedia.org,logsteralarms@wikimedia.org -t 2'",
    }

    # TODO: set configurable rate to alarm
    # logster::job{'badpass':
    #    parser          => '--output stdout AlarmCounterLogster',
    #    logfile         => '/srv/mw-log/badpass.log',
    #    logster_options => "--parser-option='-a /etc/logster/badpass -s /srv/security/logs/badpass.log -n badpass -e logsteralarms@wikimedia.org'",
    #}
}
