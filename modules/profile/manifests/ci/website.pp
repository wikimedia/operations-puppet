# SPDX-License-Identifier: Apache-2.0
# Websites for Continuous integration
#
# https://integration.wikimedia.org/ or
# https://zuul-legacy.wikimedia.org/
#
class profile::ci::website(
    String $type = lookup('profile::ci::website::type',
    {default_value => 'integration'}),
){

    case $type {
        'integration': {
            $scap_target = 'integration/docroot'
            $deploy_user = 'deploy-ci-docroot'
            $site_name = 'integration.wikimedia.org'
            $monitor_string = 'Integration'
        }
        'zuul-legacy': {
            $scap_target = 'integration/docroot'
            $deploy_user = 'deploy-ci-docroot'
            $site_name = 'zuul-legacy.wikimedia.org'
            $monitor_string = 'Zuul'
        }
        default: {
            fail("Unsupported type: ${type}")
        }
    }

    scap::target { $scap_target:
        deploy_user => $deploy_user,
    }

    # Apache configuration
    httpd::site { $site_name:
        source => "puppet:///modules/contint/apache/${site_name}.conf"
    }

    profile::auto_restarts::service { 'envoyproxy': }

    if $profile::ci::manager {
        prometheus::blackbox::check::http { $site_name:
            team               => 'collaboration-services',
            severity           => 'task',
            path               => '/',
            ip_families        => ['ip4'],
            force_tls          => true,
            port               => 1443,
            body_regex_matches => [$monitor_string],
        }
    }
}
