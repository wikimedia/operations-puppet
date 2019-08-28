# setup a webserver for misc. apps
class profile::misc_apps::httpd (
    $deployment_server = hiera('deployment_server'),
){

    $apache_modules_common = ['rewrite', 'headers', 'authnz_ldap', 'proxy', 'proxy_http']

    if os_version('debian == stretch') {
        require_package('libapache2-mod-php7.0')
        $apache_modules = concat($apache_modules_common, 'php7.0')
    } else {
        $apache_modules = concat($apache_modules_common, 'php5')
    }

    class { '::httpd':
        modules => $apache_modules,
    }

    ferm::service { 'miscweb-http-deployment':
        proto  => 'tcp',
        port   => '80',
        srange => "(@resolve((${deployment_server})) @resolve((${deployment_server}), AAAA))"
    }
}
