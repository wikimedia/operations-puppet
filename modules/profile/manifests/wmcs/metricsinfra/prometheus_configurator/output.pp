define profile::wmcs::metricsinfra::prometheus_configurator::output (
    String $kind,
    Hash $options = {},
) {
    $safe_title = $title.regsubst('[^\w\-]', '_', 'G')

    if $options['units_to_reload'] {
        sudo::user { "prometheus-configurator-${safe_title}":
            user       => 'prometheus-configurator',
            privileges => $options['units_to_reload'].map |String $unit| {
                "ALL = NOPASSWD: /usr/bin/systemctl reload ${unit}"
            },
            notify     => Exec['prometheus-configurator'],
        }
    }

    $config = {
        outputs => [
            $options + {
                kind => $kind,
            }
        ],
    }

    file { "/etc/prometheus-configurator/config.d/output_${safe_title}.yaml":
        ensure  => present,
        owner   => 'prometheus-configurator',
        group   => 'prometheus-configurator',
        content => ordered_yaml($config),
        mode    => '0440',
        notify  => Exec['prometheus-configurator'],
    }
}
