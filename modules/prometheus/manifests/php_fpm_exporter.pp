# == Define: prometheus::php_fpm_exporter
#
# Prometheus exporter for php-fpm server metrics.
#
# === Parameters
#
# [*fcgi_endpoint*]
#   The fastcgi endpoint to connect to.
#
# [*http_endpoint*]
#   The http endpoint to connect to. You need to set either this or
#   the fcgi_endpoint parameter
#
# [*port*]
#   Port on which to listen to

class prometheus::php_fpm_exporter (
    Wmflib::UserIpPort $port,
    Optional[String] $fcgi_endpoint = undef,
    Optional[Stdlib::Httpurl] $http_endpoint = undef,
) {
    if $fcgi_endpoint == undef and $http_endpoint == undef {
        fail('You need to set either `fcgi_endpoint` or `http_endpoint`')
    }
    $sw_name = 'prometheus-php-fpm-exporter'
    $listen_address = "${::ipaddress}:${port}"
    package { $sw_name:
        ensure => present,
    }

    file { '/etc/default/prometheus-php-fpm-exporter':
        ensure  => present,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('prometheus/php-fpm-exporter.default.erb'),
        notify  => Service[$sw_name],
    }

    service { $sw_name:
        ensure  => running,
        require => Package[$sw_name],
    }

    base::service_auto_restart { $sw_name: }
}
