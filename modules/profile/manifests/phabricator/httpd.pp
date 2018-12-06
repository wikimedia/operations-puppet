# sets up a webserver configured for phabricator
#
class profile::phabricator::httpd (
    Boolean $enable_php_fpm = hiera('phabricator_enable_php_fpm', false),
) {

    $httpd_base_modules = [ 'headers', 'rewrite', 'remoteip' ]

    if os_version('debian >= stretch') {
        if $enable_php_fpm {
            $httpd_extra_modules = [ 'proxy', 'proxy_fcgi' ]
            $php_lib = 'php7.2-fpm'
        } else {
            $httpd_extra_modules = [ 'php7.2' ]
            $php_lib = 'libapache2-mod-php7.2'
        }
    } else {
        $httpd_extra_modules = [ 'php5' ]
        $php_lib = 'libapache2-mod-php5'
    }

    $httpd_modules = concat($httpd_base_modules, $httpd_extra_modules)

    class { '::httpd':
        modules => $httpd_modules,
        require => Package[$php_lib],
    }

    $threads_per_child = 25
    $apache_server_limit = $::processorcount
    $max_req_workers = $threads_per_child * $apache_server_limit

    $mpm = $enable_php_fpm ? {
        true => 'worker',
        default => 'prefork'
    }

    $mpm_source = $enable_php_fpm ? {
        true => undef,
        default => 'puppet:///modules/phabricator/apache/mpm_prefork.conf'
    }

    $mpm_content = $enable_php_fpm ? {
        true => template('phabricator/apache/worker.conf.erb'),
        default => undef,
    }

    # MPM tweaks for high load systems
    # More performance specific tweaks to follow here
    class { '::httpd::mpm':
        mpm     => $mpm,
        source  => $mpm_source,
        content => $mpm_content,
    }
}
