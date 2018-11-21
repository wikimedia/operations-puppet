# === Class profile::prometheus::php_fpm_exporter
#
# Installs and configures the prometheus php-fpm exporter.
class profile::prometheus::php_fpm_exporter (
    $fcgi_port = hiera('profile::php_fpm::fcgi_port'),
    $prometheus_nodes = hiera('prometheus_nodes'),
) {
    class { 'prometheus::php_fpm_exporter':
        port          => 9180,
        fcgi_endpoint => "tcp://127.0.0.1:${fcgi_port}"
    }
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    ferm::service { 'prometheus-php-fpm-exporter':
        proto  => 'tcp',
        port   => '9180',
        srange => $ferm_srange,
    }
}
