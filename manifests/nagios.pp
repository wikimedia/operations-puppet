# nagios.pp

$nagios_config_dir = '/etc/nagios'

$ganglia_url = 'http://ganglia.wikimedia.org'

define monitor_host(
    $ip_address    = $::ipaddress,
    $group         = $nagios_group,
    $ensure        = present,
    $critical      = 'false',
    $contact_group = 'admins'
)
{
    if ! $ip_address {
        fail("Parameter $ip_address not defined!")
    }

    # Determine the hostgroup:
    # If defined in the declaration of resource, we use it;
    # If not, adopt the standard format
    $hostgroup = $group ? {
        /.+/    => $group,
        default => $cluster ? {
            default => "${cluster}_${::site}"
        }
    }

    # Export the nagios host instance
    @@nagios_host { $title:
        ensure               => $ensure,
        target               => "${::nagios_config_dir}/puppet_hosts.cfg",
        host_name            => $title,
        address              => $ip_address,
        hostgroups           => $hostgroup,
        check_command        => 'check_ping!500,20%!2000,100%',
        check_period         => '24x7',
        max_check_attempts   => 2,
        contact_groups       => $critical ? {
            'true'  => 'admins,sms',
            default => $contact_group,
        },
        notification_interval => 0,
        notification_period   => '24x7',
        notification_options  => 'd,u,r,f',
    }

    if $title == $::hostname {
        $image = $::operatingsystem ? {
            'Ubuntu'  => 'ubuntu',
            default   => 'linux40'
        }

        # Couple it with some hostextinfo
        @@nagios_hostextinfo { $title:
            ensure          => $ensure,
            target          => "${::nagios_config_dir}/puppet_hostextinfo.cfg",
            host_name       => $title,
            notes           => $title,
            icon_image      => "${image}.png",
            vrml_image      => "${image}.png",
            statusmap_image => "${image}.gd2",
        }
    }
}

define monitor_service(
    $description,
    $check_command,
    $host                  = $::hostname,
    $retries               = 3,
    $group                 = undef,
    $ensure                = present,
    $critical              = 'false',
    $passive               = 'false',
    $freshness             = 36000,
    $normal_check_interval = 1,
    $retry_check_interval  = 1,
    $contact_group         = 'admins'
)
{
    if ! $host {
        fail("Parameter $host not defined!")
    }

    if $group != undef {
        $servicegroup = $group
    }
    elsif $nagios_group != undef {
        # nagios group should be defined at the node level with hiera.
        $servicegroup = $nagios_group
    } else {
        # this check is part of no servicegroup.
        $servicegroup = undef
    }

        # Export the nagios service instance
        @@nagios_service { "$::hostname $title":
            ensure                  => $ensure,
            target                  => "${::nagios_config_dir}/puppet_checks.d/${host}.cfg",
            host_name               => $host,
            servicegroups           => $servicegroup,
            service_description     => $description,
            check_command           => $check_command,
            max_check_attempts      => $retries,
            normal_check_interval   => $normal_check_interval,
            retry_check_interval    => $retry_check_interval,
            check_period            => '24x7',
            notification_interval   => $critical ? {
                'true'  => 240,
                default => 0,
            },
            notification_period     => '24x7',
            notification_options    => 'c,r,f',
            contact_groups          => $critical ? {
                'true'  => 'admins,sms',
                default => $contact_group,
            },
            passive_checks_enabled  => 1,
            active_checks_enabled   => $passive ? {
                'true'  => 0,
                default => 1,
            },
            is_volatile             => $passive ? {
                'true'  => 1,
                default => 0,
            },
            check_freshness         => $passive ? {
                'true'  => 1,
                default => 0,
            },
            freshness_threshold     => $passive ? {
                'true'  => $freshness,
                default => undef,
            },
    }
}

define monitoring::group ($description, $ensure=present) {
    # Nagios hostgroup instance
    nagios_hostgroup { $title:
        ensure         => $ensure,
        target         => "${::nagios_config_dir}/puppet_hostgroups.cfg",
        hostgroup_name => $title,
        alias          => $description,
    }

    # Nagios servicegroup instance
    nagios_servicegroup { $title:
        ensure            => $ensure,
        target            => "${::nagios_config_dir}/puppet_servicegroups.cfg",
        servicegroup_name => $title,
        alias             => $description,
    }
}
