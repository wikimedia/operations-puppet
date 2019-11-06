# Installs and updates httpbb test harness, and installs test suites.
class profile::httpbb {
    class {'::httpbb':}

    httpbb::test_suite {'baseurls.yaml':
        source => 'puppet:///modules/profile/httpbb/baseurls.yaml'
    }

    systemd::timer::job { 'git_pull_httpbb':
        ensure          => present,
        description     => 'Pull changes from operations/software/httpbb',
        command         => '/bin/bash -c "cd /srv/deployment/httpbb && /usr/bin/git pull >/dev/null 2>&1"',
        interval        => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:*:00', # every minute
        },
        logging_enabled => false,
        user            => 'root',
    }
}
