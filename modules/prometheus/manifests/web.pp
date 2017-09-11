# == Define prometheus::web
#
# Provision a reverse proxy with nginx towards a prometheus instance.
#
# = Parameters
#
# [*proxy_pass*]
#   The address to proxy to, usually in the form of
#   'http://localhost:<prometheus_port>/<prometheus_name>'

define prometheus::web (
    $proxy_pass,
    $ensure = present,
) {
    include ::prometheus

    include ::apache::mod::proxy
    include ::apache::mod::proxy_http

    # Apache configuration snippet with proxy pass.
    $title_safe  = regsubst($title, '[\W_]', '-', 'G')
    file { "/etc/prometheus-apache/${title_safe}.conf":
        ensure  => $ensure,
        content => template('prometheus/prometheus-apache.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    # Single prometheus nginx site, will include /etc/prometheus-nginx/*.conf
    if !defined(Apache::Site['prometheus']) {
        apache::site{ 'prometheus':
            source  => 'puppet:///modules/prometheus/prometheus-apache.conf'
        }
    }
}
