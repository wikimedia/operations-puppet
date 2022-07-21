# === Class profile::prometheus::php_fpm_exporter
#
# Installs and configures the prometheus php-fpm exporter.
class profile::prometheus::php_fpm_exporter (
    Optional[Stdlib::Port::User] $fcgi_port        = lookup('profile::php_fpm::fcgi_port', {'default_value' => undef}),
    String                       $fcgi_pool        = lookup('profile::mediawiki::fcgi_pool', {'default_value' => 'www'}),
){

    if $fcgi_port == undef {
        $fcgi_endpoint = "unix:///run/php/fpm-${fcgi_pool}.sock"
    }
    else {
        $fcgi_endpoint = "tcp://127.0.0.1:${fcgi_port}"
    }
    class { 'prometheus::php_fpm_exporter':
        ensure        => 'absent',
        port          => 9180,
        fcgi_endpoint => $fcgi_endpoint
    }
}
