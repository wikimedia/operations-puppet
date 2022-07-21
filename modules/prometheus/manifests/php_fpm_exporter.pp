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
    Stdlib::Port::User $port,
    Wmflib::Ensure $ensure = 'present',
    Optional[String] $fcgi_endpoint = undef,
    Optional[Stdlib::Httpurl] $http_endpoint = undef,
) {
    if $fcgi_endpoint == undef and $http_endpoint == undef {
        fail('You need to set either `fcgi_endpoint` or `http_endpoint`')
    }
    $sw_name = 'prometheus-php-fpm-exporter'
    $listen_address = "${::ipaddress}:${port}"
    package { $sw_name:
        ensure => $ensure,
    }

    file { '/etc/default/prometheus-php-fpm-exporter':
        ensure  => $ensure,
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('prometheus/php-fpm-exporter.default.erb'),
        notify  => Service[$sw_name],
    }

    # We need to run as www-data so we can access php-fpm if it's running via
    # a unix socket
    systemd::service { $sw_name:
        ensure   => $ensure,
        content  => "[Service]\nUser=www-data",
        override => true,
        restart  => true,
        require  => Package[$sw_name],
    }

    profile::auto_restarts::service { $sw_name:
        ensure => $ensure,
    }
}
