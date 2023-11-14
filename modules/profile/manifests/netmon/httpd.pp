class profile::netmon::httpd (
){

    $php_version_number = wmflib::debian_php_version()
    $php_version = "php${php_version_number}"

    # needed by librenms and netbox web servers
    class { '::sslcert::dhparam': }

    class { '::httpd::mpm':
        mpm => 'prefork'
    }

    class { '::httpd':
        modules    => ['headers','rewrite','proxy','proxy_http','ssl','fcgid', $php_version],
        extra_pkgs => ['libapache2-mod-fcgid'],
    }

    profile::auto_restarts::service { 'apache2': }
}
