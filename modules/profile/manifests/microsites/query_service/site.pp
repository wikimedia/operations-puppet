# SPDX-License-Identifier: Apache-2.0
# A single site served by Wikibase Query Service GUI, including its monitoring
#
# $domain_name - The domain name to respond to
# $deploy_name - Name used to find site specific assets in deployment.
define profile::microsites::query_service::site(
    String $domain_name,
    String $deploy_name = $title
) {
    httpd::site { $domain_name:
        content => template('profile/query_service/httpd.erb')
    }

    prometheus::blackbox::check::http { $domain_name:
        server_name => $domain_name,
        team        => 'search-platform',
        severity    => 'task',
        path        => '/',
        force_tls   => true,
        ip_families => [ip4],
    }

    prometheus::blackbox::check::http { "${domain_name}-collab":
        server_name => $domain_name,
        team        => 'collaboration-services',
        severity    => 'task',
        path        => '/',
        force_tls   => true,
        ip_families => [ip4],
    }

}
