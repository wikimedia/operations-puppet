# SPDX-License-Identifier: Apache-2.0
class profile::orchestrator::web {
    class { 'httpd':
        modules => ['headers', 'proxy', 'proxy_http', 'rewrite', 'ssl', 'macro'],
    }
    class { 'sslcert::dhparam': }

    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)
    include profile::idp::client::httpd

    ferm::service { 'orchestrator-http-https':
        proto => 'tcp',
        port  => [80,443],
    }

    profile::auto_restarts::service { 'apache2': }
}
