# setup a webserver for misc. apps
class profile::misc_apps::httpd {

    $apache_modules_common = ['ssl', 'rewrite', 'headers', 'authnz_ldap', 'proxy', 'proxy_http']

    if os_version('debian == stretch') {
        require_package('libapache2-mod-php7.0')
        $apache_modules = concat($apache_modules_common, 'php7.0')

        apt::repository { 'wikimedia-php72':
            uri        => 'http://apt.wikimedia.org/wikimedia',
            dist       => "${::lsbdistcodename}-wikimedia",
            components => 'component/php72',
            notify     => Exec['apt_update_php'],
        }

    } else {
        $apache_modules = concat($apache_modules_common, 'php5')
    }

    class { '::httpd':
        modules => $apache_modules,
    }
}
