# == Installs and updates httpbb test harness, and installs test suites.
#
# == Properties
#
# [*basicauth_credentials*]
#   Hash containing possible credentials to be passed to tests, in form of:
#   test_name:
#     user: password
#   The hash will be translated (for being used in Authorization headers) into:
#   test_name:
#     user: Basic base64($user:$password)
#

class profile::httpbb (
    Optional[Hash[String, Hash[String, String]]] $plain_basicauth_credentials = lookup('profile::httpbb::basicauth_credentials', {default_value => undef}),
){
    class {'::httpbb':}

    # Walk over the credentials hash and turn "user: password" into "user: base64(...)"
    # leaving the structure intact.
    if $plain_basicauth_credentials {
        $basicauth_credentials = $plain_basicauth_credentials.map |$k, $v| {
            {
                $k=> $v.map |$user, $password| {
                    {$user => "Basic ${base64('encode', "${user}:${password}", 'strict') }"}
                }.reduce({}) |$m, $v| {
                    $m.merge($v)
                }
            }
        }.reduce({}) |$mem, $val| {
            $mem.merge($val)
        }
    }

    file {
        [
            '/srv/deployment/httpbb-tests/appserver',
            '/srv/deployment/httpbb-tests/miscweb',
            '/srv/deployment/httpbb-tests/people',
            '/srv/deployment/httpbb-tests/releases',
            '/srv/deployment/httpbb-tests/doc',
            '/srv/deployment/httpbb-tests/parse',
            '/srv/deployment/httpbb-tests/docker-registry',
        ]:
            ensure => directory
    }

    httpbb::test_suite {'appserver/test_foundation.yaml':
        source => 'puppet:///modules/profile/httpbb/appserver/test_foundation.yaml'
    }
    httpbb::test_suite {'appserver/test_main.yaml':
        source => 'puppet:///modules/profile/httpbb/appserver/test_main.yaml'
    }
    httpbb::test_suite {'appserver/test_nonexistent.yaml':
        source => 'puppet:///modules/profile/httpbb/appserver/test_nonexistent.yaml'
    }
    httpbb::test_suite {'appserver/test_redirects.yaml':
        source => 'puppet:///modules/profile/httpbb/appserver/test_redirects.yaml'
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
    httpbb::test_suite {'appserver/test_wwwportals.yaml':
        source => 'puppet:///modules/profile/httpbb/appserver/test_wwwportals.yaml'
    }
    httpbb::test_suite {'miscweb/test_miscweb.yaml':
        source => 'puppet:///modules/profile/httpbb/miscweb/test_miscweb.yaml'
    }
    httpbb::test_suite {'people/test_people.yaml':
        source => 'puppet:///modules/profile/httpbb/people/test_people.yaml'
    }
    httpbb::test_suite {'releases/test_releases.yaml':
        source => 'puppet:///modules/profile/httpbb/releases/test_releases.yaml'
    }
    httpbb::test_suite {'doc/test_doc.yaml':
        source => 'puppet:///modules/profile/httpbb/doc/test_doc.yaml'
    }
    httpbb::test_suite {'parse/test_parse.yaml':
        source => 'puppet:///modules/profile/httpbb/parse/test_parse.yaml'
    }

    if $basicauth_credentials and $basicauth_credentials['docker-registry'] {
        httpbb::test_suite {'docker-registry/test_docker-registry.yaml':
            content => template('profile/httpbb/docker-registry/test_docker-registry.yaml.erb'),
            mode    => '0400',
        }
    }

    systemd::timer::job { 'git_pull_httpbb':
        ensure          => present,
        description     => 'Pull changes from operations/software/httpbb',
        command         => '/bin/bash -c "cd /srv/deployment/httpbb && /usr/bin/git pull >/dev/null 2>&1"',
        interval        => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:00:00', # every hour
        },
        logging_enabled => false,
        user            => 'root',
    }
}
