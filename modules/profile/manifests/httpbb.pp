# Installs and updates httpbb test harness, and installs test suites.
class profile::httpbb {
    class {'::httpbb':}

    httpbb::test_suite {'baseurls.yaml':
        source => 'puppet:///modules/profile/httpbb/baseurls.yaml'
    }
    httpbb::test_suite {'test_foundation.yaml':
        source => 'puppet:///modules/profile/httpbb/test_foundation.yaml'
    }
    httpbb::test_suite {'test_main.yaml':
        source => 'puppet:///modules/profile/httpbb/test_main.yaml'
    }
    httpbb::test_suite {'test_remnant.yaml':
        source => 'puppet:///modules/profile/httpbb/test_remnant.yaml'
    }
    httpbb::test_suite {'test_search.yaml':
        source => 'puppet:///modules/profile/httpbb/test_search.yaml'
    }
    httpbb::test_suite {'test_secure.yaml':
        source => 'puppet:///modules/profile/httpbb/test_secure.yaml'
    }
    httpbb::test_suite {'test_wikimania_wikimedia.yaml':
        source => 'puppet:///modules/profile/httpbb/test_wikimania_wikimedia.yaml'
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
