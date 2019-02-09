# = class: profile::hmmp
#
# Sets up a simple LAMP server for use by arbitrary php applications.
#
# A new LAMP or HMMP.
#
# (L)inux (A)pache (httpd) (M)emcached (M)ariaDB (P)HP
#
# Started as a copy and then replaces role::simplelamp.
#
# Uses the httpd module instead of the apache module and the
# mariadb module instead of the mysql module.
#
# The intention is to let projects migrates to the new class
# without having to do all at once and once done rename this back
# to the original name.
#
# filtertags: labs-common
class profile::hmmp {

    $sqldata_dir = '/srv/sqldata'

    if os_version('debian >= stretch') {
        $php_module = 'php7.0'
        require_package('php-cli')
    } else {
        $php_module = 'php5'
        require_package('php5-cli')
    }

    require_package("libapache2-mod-${php_module}")

    class { '::httpd':
        modules => ['rewrite', $php_module],
    }

    class { '::memcached': }

    class { '::mariadb::packages': }

    class { '::mariadb::config':
        basedir => '/usr',
        datadir => $sqldata_dir,
    }
}
