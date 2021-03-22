# setup a webserver as required for Tendril and dbtree.
# Add Apache sites and monitoring for http/https.
class profile::tendril::webserver (
    Boolean $monitor_https = lookup('do_acme', {'default_value' => true}),
    Boolean $monitor_auth  = lookup('monitor_auth', {'default_value' => true}),
) {
    case debian::codename() {
        'buster': {
            $php_module = 'php5.6'
            $packages = ['libapache2-mod-php5.6','php5.6-mysql']
        }
        'stretch': {
            $php_module = 'php7.0'
            $packages = ['libapache2-mod-php','php-mysql']
        }
        'jessie': {
            $php_module = 'php5'
            $packages = ['libapache2-mod-php5','php5-mysql']
        }
        default: {
            fail("Please update ${module_name} to support newer php installed module")
        }
    }
    ensure_packages($packages)

    class { 'httpd':
        modules => ['rewrite',
                    'headers',
                    'ssl',
                    'authnz_ldap',
                    ],
    }

    # mod-php can only work with the prefork MPM
    class { 'httpd::mpm':
        mpm => 'prefork',
    }

    httpd::mod_conf { $php_module:
        ensure => present,
    }

    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)

    httpd::site { 'dbtree.wikimedia.org':
        content => template('dbtree/dbtree.wikimedia.org.erb'),
    }

    base::service_auto_restart { 'apache2': }

    # HTTPS monitoring, if enabled
    if $monitor_https {
        monitoring::service { 'https-dbtree':
            description   => 'HTTPS-dbtree',
            check_command => 'check_https_url!dbtree.wikimedia.org!https://dbtree.wikimedia.org',
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Dbtree.wikimedia.org',
        }
        monitoring::service { 'https-tendril':
            description   => 'HTTPS-tendril',
            check_command => 'check_ssl_http_letsencrypt!tendril.wikimedia.org',
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Tendril',
        }
    }

    # TODO: Remove when fully migrated to CAS
    if $monitor_auth {
        monitoring::service { 'https-tendril-unauthorized':
            description   => 'Tendril requires authentication',
            check_command => 'check_https_unauthorized!tendril.wikimedia.org!/!401',
            contact_group => 'admins',
            notes_url     => 'https://wikitech.wikimedia.org/wiki/Tendril',
        }
    }
}
