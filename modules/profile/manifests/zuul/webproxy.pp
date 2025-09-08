# SPDX-License-Identifier: Apache-2.0
# new zuul (T393873) - main nodes - webserver/proxy
class profile::zuul::webproxy {

    class { 'httpd':
        modules => ['headers',
                    'rewrite',
                    'proxy',
                    'proxy_http',
                    'proxy_wstunnel'
        ],
        require => File['/var/www/zuul'],
    }

    httpd::site { 'zuul.wikimedia.org':
        source => 'puppet:///modules/zuul/zuul.wikimedia.org.conf'
    }

    profile::auto_restarts::service { 'apache2': }

    # allow caching layer to connect to backend of https://zuul.wikimedia.org
    firewall::service { 'zuul-https':
        proto    => 'tcp',
        port     => 443,
        src_sets => ['CACHES', 'DEPLOYMENT_HOSTS'],
    }

    # allow deployment hosts to speak plain http to backend for testing
    firewall::service { 'zuul-http':
        proto    => 'tcp',
        port     => 80,
        src_sets => ['DEPLOYMENT_HOSTS'],
    }

}
