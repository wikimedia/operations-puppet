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
# [*hourly_tests*]
#   Hash containing a mapping of tests to be run hourly. Each key is a directory
#   name under httpbb-tests/, each value is an array of hostnames to pass to
#   --hosts. If the array is empty, sets ensure => absent.

class profile::httpbb (
    Optional[Hash[String, Hash[String, String]]] $plain_basicauth_credentials = lookup('profile::httpbb::basicauth_credentials', {default_value => undef}),
    Hash[String, Array[String]] $hourly_tests = lookup('profile::httpbb::hourly_tests', {default_value => {}})
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
    } else {
        $basicauth_credentials = undef
    }

    file {
        [
            '/srv/deployment/httpbb-tests/appserver',
            '/srv/deployment/httpbb-tests/apple-search',
            '/srv/deployment/httpbb-tests/miscweb',
            '/srv/deployment/httpbb-tests/people',
            '/srv/deployment/httpbb-tests/releases',
            '/srv/deployment/httpbb-tests/noc',
            '/srv/deployment/httpbb-tests/doc',
            '/srv/deployment/httpbb-tests/parse',
            '/srv/deployment/httpbb-tests/thumbor',
            '/srv/deployment/httpbb-tests/docker-registry',
            '/srv/deployment/httpbb-tests/ores',
        ]:
            ensure => directory,
            purge  => true
    }

    httpbb::test_suite {'appserver/test_foundation.yaml':
        source => 'puppet:///modules/profile/httpbb/appserver/test_foundation.yaml'
    }
    httpbb::test_suite {'appserver/test_main.yaml':
        source => 'puppet:///modules/profile/httpbb/appserver/test_main.yaml'
    }
    httpbb::test_suite {'appserver/test_redirects.yaml':
        source => 'puppet:///modules/profile/httpbb/appserver/test_redirects.yaml'
    }
    httpbb::test_suite {'appserver/test_remnant.yaml':
        source => 'puppet:///modules/profile/httpbb/appserver/test_remnant.yaml'
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
    httpbb::test_suite {'apple-search/test_search.yaml':
        source => 'puppet:///modules/profile/httpbb/apple-search/test_search.yaml'
    }
    httpbb::test_suite {'miscweb/test_miscweb.yaml':
        source => 'puppet:///modules/profile/httpbb/miscweb/test_miscweb.yaml'
    }
    httpbb::test_suite {'miscweb/test_miscweb-k8s.yaml':
        source => 'puppet:///modules/profile/httpbb/miscweb-k8s/test_miscweb-k8s.yaml'
    }
    httpbb::test_suite {'people/test_people.yaml':
        source => 'puppet:///modules/profile/httpbb/people/test_people.yaml'
    }
    httpbb::test_suite {'releases/test_releases.yaml':
        source => 'puppet:///modules/profile/httpbb/releases/test_releases.yaml'
    }
    httpbb::test_suite {'noc/test_noc.yaml':
        source => 'puppet:///modules/profile/httpbb/noc/test_noc.yaml'
    }
    httpbb::test_suite {'doc/test_doc.yaml':
        source => 'puppet:///modules/profile/httpbb/doc/test_doc.yaml'
    }
    httpbb::test_suite {'parse/test_parse.yaml':
        source => 'puppet:///modules/profile/httpbb/parse/test_parse.yaml'
    }
    httpbb::test_suite {'thumbor/test_thumbor.yaml':
        source => 'puppet:///modules/profile/httpbb/thumbor/test_thumbor.yaml'
    }
    httpbb::test_suite {'ores/test_ores.yaml':
        source => 'puppet:///modules/profile/httpbb/ores/test_ores.yaml'
    }

    if $basicauth_credentials and $basicauth_credentials['docker-registry'] {
        httpbb::test_suite {'docker-registry/test_docker-registry.yaml':
            content => template('profile/httpbb/docker-registry/test_docker-registry.yaml.erb'),
            mode    => '0400',
        }
    }

    $hourly_tests.each |String $test_dir, Array[String] $hosts| {
        $joined_hosts = join($hosts, ',')
        $ensure = $hosts ? {
            []      => absent,
            default => present
        }
        systemd::timer::job { "httpbb_hourly_${test_dir}":
            ensure             => $ensure,
            description        => "Run httpbb ${test_dir}/ tests hourly on ${joined_hosts}",
            command            => "/bin/sh -c '/usr/bin/httpbb /srv/deployment/httpbb-tests/${test_dir}/*.yaml --hosts ${joined_hosts}'",
            interval           => {
                'start'    => 'OnUnitActiveSec',
                'interval' => '1 hour',
            },
            # This doesn't really need access to anything in www-data, but it definitely doesn't need root.
            user               => 'www-data',
            monitoring_enabled => true,
        }
    }
}
