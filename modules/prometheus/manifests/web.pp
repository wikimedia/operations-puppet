# == Define prometheus::web
#
# Provision a reverse proxy with apache towards a prometheus instance.
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

    # Previously installed hosts with this class used nginx;
    #  turn off and remove nginx to avoid collisions
    #  on port 80.
    if !defined(Class['::nginx']) {
        class { '::nginx':
            ensure => absent,
        }
    }

    # Apache configuration snippet with proxy pass.
    $title_safe  = regsubst($title, '[\W_]', '-', 'G')
    file { "/etc/apache2/prometheus.d/${title_safe}.conf":
        ensure  => $ensure,
        content => template('prometheus/prometheus-apache.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    # Single prometheus apache site, will include /etc/prometheus-apache/*.conf
    if !defined(Httpd::Site['prometheus']) {
        httpd::site{ 'prometheus':
            source  => 'puppet:///modules/prometheus/prometheus-apache.conf'
        }
    }
}
