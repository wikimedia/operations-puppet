# Installs and updates httpbb test harness, and installs test suites.
class profile::httpbb {
    class {'::httpbb':}

    file {
        [
            '/srv/deployment/httpbb-tests/appserver',
            '/srv/deployment/httpbb-tests/miscweb',
        ]:
            ensure => directory
    }

    httpbb::test_suite {'appserver/baseurls.yaml':
        source => 'puppet:///modules/profile/httpbb/appserver/baseurls.yaml'
    }
    httpbb::test_suite {'appserver/test_foundation.yaml':
        source => 'puppet:///modules/profile/httpbb/appserver/test_foundation.yaml'
    }
    httpbb::test_suite {'appserver/test_main.yaml':
        source => 'puppet:///modules/profile/httpbb/appserver/test_main.yaml'
    }
    httpbb::test_suite {'appserver/test_remnant.yaml':
        source => 'puppet:///modules/profile/httpbb/appserver/test_remnant.yaml'
    }
    httpbb::test_suite {'appserver/test_search.yaml':
        source => 'puppet:///modules/profile/httpbb/appserver/test_search.yaml'
    }
    httpbb::test_suite {'appserver/test_secure.yaml':
        source => 'puppet:///modules/profile/httpbb/appserver/test_secure.yaml'
    }
    httpbb::test_suite {'appserver/test_wikimania_wikimedia.yaml':
        source => 'puppet:///modules/profile/httpbb/appserver/test_wikimania_wikimedia.yaml'
    }
    httpbb::test_suite {'miscweb/test_miscweb.yaml':
        source => 'puppet:///modules/profile/httpbb/miscweb/test_miscweb.yaml'
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
