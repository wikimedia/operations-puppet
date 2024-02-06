# SPDX-License-Identifier: Apache-2.0
# == define confd::instance
#
# Sets up and (optionally) starts it via a base::service_unit define.
#
# === Parameters
#
# [*running*] If true, the service will be ran. Default: true
#
# [*backend*] The backend to use. Default: etcd
#
# [*hosts*] URLs of specific backend nodes to connect to.
#           Default: undef
#
# [*srv_dns*] The domain under which to perform a SRV query to discover the
#             backend cluster. Default: $::domain
#
# [*scheme*] Protocol ("http" or "https"). Default: https
#
# [*interval*] Polling interval to etcd. If undefined, a direct watch will be
#              executed (the default)
#
# [*prefix*] A global prefix with respect to which confd will do all of its
#            operations. Default: undef
define confd::instance (
    Wmflib::Ensure                   $ensure        = present,
    Boolean                          $running       = true,
    String                           $backend       = 'etcd',
    Optional[Array[Stdlib::HTTPUrl]] $hosts         = undef,
    Stdlib::Fqdn                     $srv_dns       = $facts['domain'],
    String                           $scheme        = 'https',
    Integer                          $interval      = 3,
    Optional[String]                 $prefix        = undef,
) {
    assert_private()
    $label = $name ? {
        'main'  => 'confd',
        default => sprintf('confd-%s', regsubst($name, '/', '_', 'G')),
    }
    $path = "/etc/${label}"
    $params = { 'ensure' => $running.bool2str('running', 'stopped') }

    file { $path:
        ensure => directory,
        mode   => '0550',
    }

    file { "${path}/conf.d":
        ensure  => directory,
        recurse => true,
        purge   => true,
        mode    => '0550',
        before  => Service[$label],
    }

    file { "${path}/templates":
        ensure  => directory,
        recurse => true,
        purge   => true,
        mode    => '0550',
        before  => Service[$label],
    }

    # TODO: convert to use the systemd entry instead
    base::service_unit { $label:
        ensure         => $ensure,
        refresh        => true,
        systemd        => systemd_template('confd'),
        service_params => $params,
        require        => Package['confd'],
    }
    $prom_outfile = "/var/lib/prometheus/node.d/${label}_template.prom"
    $prom_opts = $name ? {
        'main' => '',
        default => " --confd.path ${path}/conf.d --outfile ${prom_outfile}"
    }
    $prom_cli = "/usr/local/bin/confd-prometheus-metrics${prom_opts}"

    systemd::timer::job { "${label}_prometheus_metrics":
        ensure      => present,
        description => 'Export confd Prometheus metrics',
        command     => $prom_cli,
        interval    => {
            'start'    => 'OnCalendar',
            'interval' => 'minutely',
        },
        user        => 'root',
    }
    # Any change to a this instances service configuration or to a template should reload confd.
    Confd::File <| instance == $name |> ~> Service[$label]
}
