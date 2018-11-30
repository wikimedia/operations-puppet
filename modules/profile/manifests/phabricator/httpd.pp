# sets up a webserver configured for phabricator
#
class profile::phabricator::httpd {

    if os_version('debian >= stretch') {
        $php_module = 'php7.2'
    } else {
        $php_module = 'php5'
    }

    $apache_lib = "libapache2-mod-${php_module}"

    class { '::httpd':
        modules => ['headers', 'rewrite', 'remoteip', $php_module],
        require => Package[$apache_lib],
    }

    # MPM tweaks for high load systems
    # More performance specific tweaks to follow here
    httpd::conf { 'mpm_prefork':
        source => 'puppet:///modules/phabricator/apache/mpm_prefork.conf',
    }
}
