class profile::netmon::httpd (
){
    $php_version = debian::codename() ? {
        'buster'   => 'php7.3',
        'bullseye' => 'php7.4',
        default    => 'php7.3',
    }
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
