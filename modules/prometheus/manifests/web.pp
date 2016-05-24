# == Define prometheus::web
#
# Provision a reverse proxy with nginx towards a prometheus instance.

define prometheus::web (
    $proxy_pass
) {
    if !defined(File['/etc/prometheus-nginx']) {
        file { '/etc/prometheus-nginx':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0555',
        }
    }

    # Nginx configuration snippet with proxy pass.
    file { "/etc/prometheus-nginx/${title}.conf":
        ensure  => file,
        content => template('prometheus/prometheus-nginx.erb'),
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
    }

    # Single prometheus nginx site, will include /etc/prometheus-nginx/*.conf
    if !defined(Nginx::Site['prometheus']) {
        nginx::site{ 'prometheus':
            source  => 'puppet:///modules/prometheus/prometheus-nginx.conf',
        }
    }
}
