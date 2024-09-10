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
    Hash[String, Array[String]] $hourly_tests = lookup('profile::httpbb::hourly_tests', {default_value => {}}),
    Boolean $test_kubernetes_hourly = lookup('profile::httpbb::test_kubernetes_hourly', {default_value => false}),
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
            '/srv/deployment/httpbb-tests/miscweb',
            '/srv/deployment/httpbb-tests/people',
            '/srv/deployment/httpbb-tests/releases',
            '/srv/deployment/httpbb-tests/gitlab',
            '/srv/deployment/httpbb-tests/vrts',
            '/srv/deployment/httpbb-tests/contint',
            '/srv/deployment/httpbb-tests/etherpad',
            '/srv/deployment/httpbb-tests/rt',
            '/srv/deployment/httpbb-tests/gerrit',
            '/srv/deployment/httpbb-tests/planet',
            '/srv/deployment/httpbb-tests/noc',
            '/srv/deployment/httpbb-tests/doc',
            '/srv/deployment/httpbb-tests/parse',
            '/srv/deployment/httpbb-tests/thumbor',
            '/srv/deployment/httpbb-tests/docker-registry',
            '/srv/deployment/httpbb-tests/query_service',
            '/srv/deployment/httpbb-tests/jobrunner',
            '/srv/deployment/httpbb-tests/phabricator',
            '/srv/deployment/httpbb-tests/liftwing',
            '/srv/deployment/httpbb-tests/liftwing/production',
            '/srv/deployment/httpbb-tests/liftwing/staging',
            '/srv/deployment/httpbb-tests/ores_legacy',
            '/srv/deployment/httpbb-tests/wikifunctions',
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
    httpbb::test_suite {'gitlab/test_gitlab.yaml':
        source => 'puppet:///modules/profile/httpbb/gitlab/test_gitlab.yaml'
    }
    httpbb::test_suite {'vrts/test_vrts.yaml':
        source => 'puppet:///modules/profile/httpbb/vrts/test_vrts.yaml'
    }
    httpbb::test_suite {'contint/test_integration.yaml':
        source => 'puppet:///modules/profile/httpbb/contint/test_integration.yaml'
    }
    httpbb::test_suite {'etherpad/test_etherpad.yaml':
        source => 'puppet:///modules/profile/httpbb/etherpad/test_etherpad.yaml'
    }
    httpbb::test_suite {'rt/test_rt.yaml':
        source => 'puppet:///modules/profile/httpbb/rt/test_rt.yaml'
    }
    httpbb::test_suite {'planet/test_planet.yaml':
        source => 'puppet:///modules/profile/httpbb/planet/test_planet.yaml'
    }
    httpbb::test_suite {'gerrit/test_gerrit.yaml':
        source => 'puppet:///modules/profile/httpbb/gerrit/test_gerrit.yaml'
    }
    httpbb::test_suite {'gerrit/test_gerrit_replica.yaml':
        source => 'puppet:///modules/profile/httpbb/gerrit/test_gerrit_replica.yaml'
    }
    httpbb::test_suite {'phabricator/test_phabricator.yaml':
        source => 'puppet:///modules/profile/httpbb/phabricator/test_phabricator.yaml'
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
    httpbb::test_suite {'query_service/test_wdqs.yaml':
        source => 'puppet:///modules/profile/httpbb/query_service/test_wdqs.yaml'
    }
    httpbb::test_suite {'jobrunner/test_endpoint.yaml':
        source => 'puppet:///modules/profile/httpbb/jobrunner/test_endpoint.yaml'
    }
    httpbb::test_suite {'liftwing/production/test_article-descriptions.yaml':
        source => 'puppet:///modules/profile/httpbb/liftwing/production/test_article-descriptions.yaml'
    }
    httpbb::test_suite {'liftwing/production/test_articletopic-outlink.yaml':
        source => 'puppet:///modules/profile/httpbb/liftwing/production/test_articletopic-outlink.yaml'
    }
    httpbb::test_suite {'liftwing/production/test_llm.yaml':
        source => 'puppet:///modules/profile/httpbb/liftwing/production/test_llm.yaml'
    }
    httpbb::test_suite {'liftwing/production/test_revertrisk.yaml':
        source => 'puppet:///modules/profile/httpbb/liftwing/production/test_revertrisk.yaml'
    }
    httpbb::test_suite {'liftwing/production/test_revscoring-articlequality.yaml':
        source => 'puppet:///modules/profile/httpbb/liftwing/production/test_revscoring-articlequality.yaml'
    }
    httpbb::test_suite {'liftwing/production/test_revscoring-articletopic.yaml':
        source => 'puppet:///modules/profile/httpbb/liftwing/production/test_revscoring-articletopic.yaml'
    }
    httpbb::test_suite {'liftwing/production/test_revscoring-draftquality.yaml':
        source => 'puppet:///modules/profile/httpbb/liftwing/production/test_revscoring-draftquality.yaml'
    }
    httpbb::test_suite {'liftwing/production/test_revscoring-drafttopic.yaml':
        source => 'puppet:///modules/profile/httpbb/liftwing/production/test_revscoring-drafttopic.yaml'
    }
    httpbb::test_suite {'liftwing/production/test_revscoring-editquality-damaging.yaml':
        source => 'puppet:///modules/profile/httpbb/liftwing/production/test_revscoring-editquality-damaging.yaml'
    }
    httpbb::test_suite {'liftwing/production/test_revscoring-editquality-goodfaith.yaml':
        source => 'puppet:///modules/profile/httpbb/liftwing/production/test_revscoring-editquality-goodfaith.yaml'
    }
    httpbb::test_suite {'liftwing/production/test_revscoring-editquality-reverted.yaml':
        source => 'puppet:///modules/profile/httpbb/liftwing/production/test_revscoring-editquality-reverted.yaml'
    }
    httpbb::test_suite {'liftwing/staging/test_article-descriptions.yaml':
        source => 'puppet:///modules/profile/httpbb/liftwing/staging/test_article-descriptions.yaml'
    }
    httpbb::test_suite {'liftwing/staging/test_articletopic-outlink.yaml':
        source => 'puppet:///modules/profile/httpbb/liftwing/staging/test_articletopic-outlink.yaml'
    }
    httpbb::test_suite {'liftwing/staging/test_llm.yaml':
        source => 'puppet:///modules/profile/httpbb/liftwing/staging/test_llm.yaml'
    }
    httpbb::test_suite {'liftwing/staging/test_revertrisk.yaml':
        source => 'puppet:///modules/profile/httpbb/liftwing/staging/test_revertrisk.yaml'
    }
    httpbb::test_suite {'liftwing/staging/test_revscoring-articlequality.yaml':
        source => 'puppet:///modules/profile/httpbb/liftwing/staging/test_revscoring-articlequality.yaml'
    }
    httpbb::test_suite {'liftwing/staging/test_revscoring-articletopic.yaml':
        source => 'puppet:///modules/profile/httpbb/liftwing/staging/test_revscoring-articletopic.yaml'
    }
    httpbb::test_suite {'liftwing/staging/test_revscoring-draftquality.yaml':
        source => 'puppet:///modules/profile/httpbb/liftwing/staging/test_revscoring-draftquality.yaml'
    }
    httpbb::test_suite {'liftwing/staging/test_revscoring-drafttopic.yaml':
        source => 'puppet:///modules/profile/httpbb/liftwing/staging/test_revscoring-drafttopic.yaml'
    }
    httpbb::test_suite {'liftwing/staging/test_revscoring-editquality-damaging.yaml':
        source => 'puppet:///modules/profile/httpbb/liftwing/staging/test_revscoring-editquality-damaging.yaml'
    }
    httpbb::test_suite {'liftwing/staging/test_revscoring-editquality-goodfaith.yaml':
        source => 'puppet:///modules/profile/httpbb/liftwing/staging/test_revscoring-editquality-goodfaith.yaml'
    }
    httpbb::test_suite {'liftwing/staging/test_revscoring-editquality-reverted.yaml':
        source => 'puppet:///modules/profile/httpbb/liftwing/staging/test_revscoring-editquality-reverted.yaml'
    }
    httpbb::test_suite {'ores_legacy/test_ores_staging.yaml':
        source => 'puppet:///modules/profile/httpbb/ores_legacy/test_ores_staging.yaml'
    }
    httpbb::test_suite {'ores_legacy/test_ores_production.yaml':
        source => 'puppet:///modules/profile/httpbb/ores_legacy/test_ores_production.yaml'
    }
    httpbb::test_suite {'wikifunctions/test_main.yaml':
        source => 'puppet:///modules/profile/httpbb/wikifunctions/test_main.yaml'
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
            command            => "/bin/sh -c '/usr/bin/httpbb /srv/deployment/httpbb-tests/${test_dir}/*.yaml --hosts ${joined_hosts} --retry_on_timeout'",
            interval           => {
                'start'    => 'OnUnitActiveSec',
                'interval' => '1 hour',
            },
            # This doesn't really need access to anything in www-data, but it definitely doesn't need root.
            user               => 'www-data',
            monitoring_enabled => true,
            team               => 'ServiceOps',
        }
    }

    # Add the hourly Kubernetes test separately, since it needs a different --https_port.
    $ensure = $test_kubernetes_hourly.bool2str('present', 'absent')
    $kubernetes_services = wmflib::service::fetch().filter |$name, $config| {
        $config.has_key('httpbb_dir')
    }
    $kubernetes_services.each |String $svc_name, Hash $svc| {
        $svc_port       = $svc['port']
        $svc_httpbb_dir = $svc['httpbb_dir']
        systemd::timer::job { "httpbb_kubernetes_${svc_name}_hourly":
            ensure             => $ensure,
            description        => "Run httpbb ${svc_httpbb_dir} tests hourly on Kubernetes ${svc_name}.",
            command            => "/bin/sh -c \'/usr/bin/httpbb /srv/deployment/httpbb-tests/${svc_httpbb_dir}/*.yaml --host ${svc_name}.discovery.wmnet --https_port ${svc_port} --retry_on_timeout\'",
            interval           => {
                'start'    => 'OnUnitActiveSec',
                'interval' => '1 hour',
            },
            user               => 'www-data',
            monitoring_enabled => true,
            team               => 'ServiceOps',
        }
    }
}
