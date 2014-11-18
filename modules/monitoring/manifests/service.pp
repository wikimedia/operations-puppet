define monitoring::service(
    $description,
    $check_command,
    $host                  = $::hostname,
    $retries               = 3,
    $group                 = $monitoring::configuration::group,
    $ensure                = present,
    $critical              = 'false',
    $passive               = 'false',
    $freshness             = 36000,
    $normal_check_interval = 1,
    $retry_check_interval  = 1,
    $contact_group         = 'admins',
    $config_dir            = $monitoring::configuration::dir,
)
{
    if ! $host {
        fail("Parameter $host not defined!")
    }

    if $group {
        $servicegroups = $group
    } else {
        $servicegroups = undef
    }

    # Export the nagios service instance
    @@nagios_service { "${::hostname} ${title}":
        ensure                  => $ensure,
        target                  => "${config_dir}/puppet_checks.d/${host}.cfg",
        host_name               => $host,
        servicegroups           => $servicegroups,
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
