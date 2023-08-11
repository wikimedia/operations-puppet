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
# @param bind_service the service for systemd to bind to
# @param do_ipv6 configure ipv6
# @param logging The logging config hash
class bird::anycast_healthchecker(
    Optional[Array[String[1], 1]] $bind_service = undef,
    Boolean                       $do_ipv6      = false,
    Bird::Anycasthc_logging       $logging      = {'level' => 'info', 'num_backups' => 8},
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

    file {'/var/run/anycast-healthchecker/':
        ensure => directory,
        owner  => 'bird',
        group  => 'bird',
        mode   => '0775',
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
        require        => File['/etc/anycast-healthchecker.conf',
        '/var/run/anycast-healthchecker/',
        '/var/log/anycast-healthchecker/',
        '/etc/anycast-healthchecker.d/',],
        restart        => true,
        service_params => {
            ensure  => 'running', # lint:ignore:ensure_first_param
            require => Service[$bind_service],
        },
    }
}
