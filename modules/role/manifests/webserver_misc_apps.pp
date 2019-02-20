# a webserver for misc. apps
# (as opposed to static websites using webserver_misc_static)
class role::webserver_misc_apps {

    system::role { 'webserver_misc_apps':
        description => 'WMF misc apps web server'
    }

    include ::standard
    include ::profile::base::firewall

    $apache_modules_common = ['ssl', 'rewrite', 'headers', 'authnz_ldap', 'proxy', 'proxy_http']

    if os_version('debian == stretch') {
        require_package('libapache2-mod-php7.0')
        $apache_modules = concat($apache_modules_common, 'php7.0')
    } else {
        $apache_modules = concat($apache_modules_common, 'php5')
    }

    class { '::httpd':
        modules => $apache_modules,
    }

    include ::profile::wikimania_scholarships # https://scholarships.wikimedia.org
    include ::profile::iegreview              # https://iegreview.wikimedia.org
    include ::profile::racktables             # https://racktables.wikimedia.org
}
