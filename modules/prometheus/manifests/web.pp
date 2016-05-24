# == Define prometheus::web
#
# Provision a reverse proxy with nginx towards a prometheus instance.

define prometheus::web (
    $proxy_pass,
    $ensure = present,
) {
    if !defined(File['/etc/prometheus-nginx']) {
        file { '/etc/prometheus-nginx':
            ensure => ensure_directory($ensure),
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
        }
    }

    # Nginx configuration snippet with proxy pass.
    $title_safe  = regsubst($title, '[\W_]', '-', 'G')
    file { "/etc/prometheus-nginx/${title_safe}.conf":
        ensure  => $ensure,
        content => template('prometheus/prometheus-nginx.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
    }

    # Single prometheus nginx site, will include /etc/prometheus-nginx/*.conf
    if !defined(Nginx::Site['prometheus']) {
        nginx::site{ 'prometheus':
            source  => 'puppet:///modules/prometheus/prometheus-nginx.conf',
        }
    }
}
