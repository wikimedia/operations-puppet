# Prometheus Varnish metrics exporter.

# === Parameters
#
# [*$instance*]
#  The varnish instance to use, passed to varnishstat -n
#
# [*$listen_address*]
#  The host:port tuple to listen on, host can be omitted.

define prometheus::varnish_exporter (
    $instance  = $::hostname,
    $listen_address = ':9131',
) {
    require_package('prometheus-varnish-exporter')

    exec { 'mask_default_varnish_exporter':
        command => '/bin/systemctl mask prometheus-varnish-exporter.service',
        creates => '/etc/systemd/system/prometheus-varnish-exporter.service',
    }

    base::service_unit { "prometheus-varnish-exporter@${instance}":
        ensure        => present,
        refresh       => true,
        systemd       => true,
        template_name => 'prometheus-varnish-exporter@',
        require       => Package['prometheus-varnish-exporter'],
    }
}
