# === Class profile::prometheus::php_fpm_exporter
#
# Installs and configures the prometheus php-fpm exporter.
class profile::prometheus::php_fpm_exporter (
    Optional[Wmflib::UserIpPort] $fcgi_port        = lookup('profile::php_fpm::fcgi_port', {'default_value' => undef}),
    String                       $fcgi_pool        = lookup('profile::mediawiki::fcgi_pool', {'default_value' => 'www'}),
    Array[Stdlib::Host]          $prometheus_nodes = lookup('prometheus_nodes'),
){

    if $fcgi_port == undef {
        $fcgi_endpoint = "unix:///run/php/fpm-${fcgi_pool}.sock"
    }
    else {
        $fcgi_endpoint = "tcp://127.0.0.1:${fcgi_port}"
    }
    class { 'prometheus::php_fpm_exporter':
        port          => 9180,
        fcgi_endpoint => $fcgi_endpoint
    }
    $prometheus_ferm_nodes = join($prometheus_nodes, ' ')
    $ferm_srange = "(@resolve((${prometheus_ferm_nodes})) @resolve((${prometheus_ferm_nodes}), AAAA))"

    ferm::service { 'prometheus-php-fpm-exporter':
        proto  => 'tcp',
        port   => '9180',
        srange => $ferm_srange,
    }
}
