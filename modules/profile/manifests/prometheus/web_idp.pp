# SPDX-License-Identifier: Apache-2.0

class profile::prometheus::web_idp {

    include ::profile::tlsproxy::envoy

    # IDP authenticated prometheus.wikimedia.org vhost
    profile::idp::client::httpd::site {"prometheus.${::site}.wikimedia.org":
        vhost_content    => 'profile/idp/client/httpd-prometheus.erb',
        proxied_as_https => true,
        document_root    => '/var/www/html',
        required_groups  => [
            'cn=ops,ou=groups,dc=wikimedia,dc=org',
            'cn=nda,ou=groups,dc=wikimedia,dc=org',
            'cn=wmf,ou=groups,dc=wikimedia,dc=org',
        ],
    }

}
