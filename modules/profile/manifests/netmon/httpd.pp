class profile::netmon::httpd (
    Float $php_version = lookup(profile::netmon::httpd::php_version, {default_value => '7.3'}),
){

    # needed by librenms and netbox web servers
    class { '::sslcert::dhparam': }

    class { '::httpd::mpm':
        mpm => 'prefork'
    }

    class { '::httpd':
        modules    => ['headers','rewrite','proxy','proxy_http','ssl','fcgid', "php${php_version}"],
        extra_pkgs => ['libapache2-mod-fcgid'],
    }
}
