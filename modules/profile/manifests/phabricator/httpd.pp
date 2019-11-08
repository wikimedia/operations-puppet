# sets up a webserver configured for phabricator
#
class profile::phabricator::httpd (
    Boolean $enable_forensic_log = hiera('profile::phabricator::httpd::enable_forensic_log', false),
    Boolean $aphlict_enabled = lookup('phabricator_aphlict_enabled', {'default_value' => false}),
) {

    $httpd_base_modules = [ 'headers', 'rewrite', 'remoteip' ]

    if os_version('debian == buster') {
        $php_lib = 'php7.3-fpm'
    } else {
        $php_lib = 'php7.2-fpm'
    }
    $httpd_extra_modules = [ 'proxy', 'proxy_fcgi' ]

    $httpd_modules = concat($httpd_base_modules, $httpd_extra_modules)

    class { '::httpd':
        modules => $httpd_modules,
        require => Package[$php_lib],
    }

    # MPM tweaks for high load systems
    # More performance specific tweaks to follow here
    class { '::httpd::mpm':
        mpm    => 'worker',
        source => 'puppet:///modules/phabricator/apache/worker.conf',
    }

    # Forensic logging (logs requests at both beginning and end of request processing)
    if $enable_forensic_log {
        ::httpd::mod_conf { 'log_forensic':
            ensure  => present,
        }

        ::httpd::conf { 'log_forensic':
            ensure  => present,
            source  => 'puppet:///modules/phabricator/apache/log_forensic.conf',
            require => Httpd::Mod_conf['log_forensic'],
        }
    }

    # Proxy websockets to aphlict if present
    if $aphlict_enabled {
        ::httpd::mod_conf { 'proxy_wstunnel': }
    }
}
