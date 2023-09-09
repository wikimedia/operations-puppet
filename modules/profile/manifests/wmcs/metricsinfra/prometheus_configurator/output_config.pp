# SPDX-License-Identifier: Apache-2.0
define profile::wmcs::metricsinfra::prometheus_configurator::output_config (
    String $kind,
    Hash   $options = {},
) {
    $safe_title = $title.regsubst('[^\w\-]', '_', 'G')

    if $options['units_to_reload'] {
        $units_to_reload_sudo = $options['units_to_reload'].map |String $unit| {
            "ALL = NOPASSWD: /usr/bin/systemctl reload ${unit}"
        }
    } else {
        $units_to_reload_sudo = []
    }

    if $options['units_to_restart'] {
        $units_to_restart_sudo = $options['units_to_restart'].map |String $unit| {
            "ALL = NOPASSWD: /usr/bin/systemctl restart ${unit}"
        }
    } else {
        $units_to_restart_sudo = []
    }

    if $options['blackbox_reload'] {
        $blackbox_reload_sudo = [
            "ALL = NOPASSWD: ${options['blackbox_reload']}"
        ]
    } else {
        $blackbox_reload_sudo = []
    }

    sudo::user { "prometheus-configurator-${safe_title}":
        user       => 'prometheus-configurator',
        privileges => $units_to_reload_sudo + $units_to_restart_sudo + $blackbox_reload_sudo,
    }

    sudo::user { [
        "prometheus-configurator-${safe_title}-reload",
        "prometheus-configurator-${safe_title}-restart",
    ]:
        ensure => absent,
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
