# setup a webserver as required for Tendril and dbtree.
# Add Apache sites and monitoring for http/https.
class profile::tendril::webserver (
    $monitor_https = hiera('do_acme', true),
) {

    # Please note dbtree doesn't currently work on stretch's php
    if os_version('debian >= stretch') {
        $php_module = 'php7.0'
        require_package('libapache2-mod-php','php-mysql')
    } else {
        $php_module = 'php5'
        require_package('libapache2-mod-php5', 'php5-mysql')
    }

    class { '::httpd':
        modules => ['rewrite',
                    'headers',
                    'ssl',
                    $php_module,
                    'authnz_ldap',
                    ],
    }

    httpd::site { 'dbtree.wikimedia.org':
        content => template('dbtree/dbtree.wikimedia.org.erb'),
    }

    # HTTP(S) monitoring
    monitoring::service { 'http-dbtree':
        description   => 'HTTP-dbtree',
        check_command => 'check_http_url!dbtree.wikimedia.org!http://dbtree.wikimedia.org',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Dbtree.wikimedia.org',
    }

    if $monitor_https {
        monitoring::service { 'https-tendril':
            description   => 'HTTPS-tendril',
            check_command => 'check_ssl_http_letsencrypt!tendril.wikimedia.org',
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Tendril',
        }
        monitoring::service { 'https-tendril-unauthorized':
            description   => 'Tendril requires authentication',
            check_command => 'check_https_unauthorized!tendril.wikimedia.org!/!401',
            contact_group => 'dba',
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Tendril',
        }
    }
}
