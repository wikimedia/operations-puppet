# SPDX-License-Identifier: Apache-2.0
# @summary
# Install and configure the base of anycast_healthchecker
# https://github.com/unixsurfer/anycast_healthchecker
#
# - Global configuration file
# - pid directory
# - Services checks directory
# - Log directory
# - systemd service
#
# The actual services checks are configured with bird::anycast_healthchecker_check
# @param do_ipv6 configure ipv6
# @param logging The logging config hash
# @param do_prom_exporter whether to enable the built-in Prometheus metrics (default: false)
# @param prom_exporter_path if the above is enabled, path for directory where metrics are exported
# @param prom_exporter_interval the scraping period for the metrics
# @param bind_service the service for systemd to bind to
# @param supplementary_groups the additional supplementary group for the anycast-hc process
class bird::anycast_healthchecker(
    Boolean                       $do_ipv6                = false,
    Bird::Anycasthc_logging       $logging                = {'level' => 'info', 'num_backups' => 8},
    Boolean                       $do_prom_exporter       = false,
    Stdlib::Unixpath              $prom_exporter_path     = '/var/lib/prometheus/node.d/',
    Integer[30]                   $prom_exporter_interval = 60,
    Optional[Array[String[1], 1]] $bind_service           = undef,
    Optional[Array[String[1], 1]] $supplementary_groups   = undef,
){

    ensure_packages(['anycast-healthchecker'])

    file {
        default:
            ensure  => file,
            owner   => 'bird',
            group   => 'bird',
            mode    => '0664',
            require => Package['anycast-healthchecker'];
        '/etc/anycast-healthchecker.conf':
            content      => template('bird/anycast-healthchecker.conf.erb'),
            validate_cmd => '/usr/bin/anycast-healthchecker -f % --check';
        '/etc/bird/anycast-prefixes.conf':
            replace      => false;  # The content is managed by anycast-healthchecker
        '/etc/bird/anycast6-prefixes.conf':
            replace      => false;  # The content is managed by anycast-healthchecker
    }

    systemd::tmpfile { 'var-run-anycast-healthchecker':
        content => 'd /var/run/anycast-healthchecker/ 0775 bird bird',
    }

    file {'/etc/anycast-healthchecker.d/':
        ensure  => directory,
        owner   => 'bird',
        group   => 'bird',
        mode    => '0775',
        purge   => true,
        recurse => true,
        notify  => Service['anycast-healthchecker'],
    }

    file {'/var/log/anycast-healthchecker/':
        ensure  => directory,
        owner   => 'bird',
        group   => 'bird',
        mode    => '0775',
        recurse => true,
        before  => Service['anycast-healthchecker'],
    }

    if $bind_service {
        $bind_service_with_ext = $bind_service.map |$srv| {
            $srv ? {
                Systemd::Service::Name => $srv,
                default                => "${srv}.service"
            }
        }
    }
    systemd::service { 'anycast-healthchecker':
        content        => template('bird/anycast-healthchecker.service.erb'),
        require        => [
            File[
                '/etc/anycast-healthchecker.conf',
                '/var/log/anycast-healthchecker/',
                '/etc/anycast-healthchecker.d/',
            ],
            Systemd::Tmpfile['var-run-anycast-healthchecker'],
        ],
        restart        => true,
        service_params => {
            ensure  => 'running', # lint:ignore:ensure_first_param
            require => Service[$bind_service],
            before  => Service['bird'],
        },
    }
}
