# setup a webserver for misc. apps
class profile::miscweb::httpd (
    Stdlib::Fqdn $deployment_server = lookup('deployment_server'),
){

    $apache_modules_common = ['rewrite', 'headers', 'proxy', 'proxy_http']
    $apache_php_module = 'php7.3'
    $apache_modules = concat($apache_modules_common, $apache_php_module)

    require_package('libapache2-mod-php')

    class { '::httpd':
        modules => $apache_modules,
    }

    base::service_auto_restart { 'apache2': }

    ferm::service { 'miscweb-http-envoy':
        proto  => 'tcp',
        port   => '80',
        srange => "(${::ipaddress} ${::ipaddress6})"
    }

    ferm::service { 'miscweb-http-deployment':
        proto  => 'tcp',
        port   => '80',
        srange => "(@resolve((${deployment_server})) @resolve((${deployment_server}), AAAA))"
    }
}
