# SPDX-License-Identifier: Apache-2.0
define profile::wmcs::metricsinfra::prometheus_configurator::output_config (
    String $kind,
    Hash $options = {},
) {
    $safe_title = $title.regsubst('[^\w\-]', '_', 'G')

    if $options['units_to_reload'] {
        sudo::user { "prometheus-configurator-${safe_title}-reload":
            user       => 'prometheus-configurator',
            privileges => $options['units_to_reload'].map |String $unit| {
                "ALL = NOPASSWD: /usr/bin/systemctl reload ${unit}"
            },
        }
    }

    if $options['units_to_restart'] {
        sudo::user { "prometheus-configurator-${safe_title}-restart":
            user       => 'prometheus-configurator',
            privileges => $options['units_to_restart'].map |String $unit| {
                "ALL = NOPASSWD: /usr/bin/systemctl restart ${unit}"
            },
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
        content => to_yaml($config),
        mode    => '0440',
    }
}
