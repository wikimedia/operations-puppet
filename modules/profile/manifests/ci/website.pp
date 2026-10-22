# SPDX-License-Identifier: Apache-2.0
# Websites for Continuous integration
#
# https://integration.wikimedia.org/ or
#
class profile::ci::website {

    $monitor_string = 'integration'
    # / redirects to /ci/ while zuul is broken (T441940)
    $monitor_path = '/ci/'

    scap::target { 'integration/docroot':
        deploy_user => 'deploy-ci-docroot',
    }

    # Apache configuration
    httpd::site { 'integration.wikimedia.org':
        source => 'puppet:///modules/contint/apache/integration.wikimedia.org.conf'
    }

    profile::auto_restarts::service { 'envoyproxy': }

    if $profile::ci::manager {
        prometheus::blackbox::check::http { 'integration.wikimedia.org':
            team               => 'collaboration-services',
            severity           => 'task',
            path               => $monitor_path,
            ip_families        => ['ip4'],
            force_tls          => true,
            port               => 1443,
            body_regex_matches => [$monitor_string],
        }
    }
}
