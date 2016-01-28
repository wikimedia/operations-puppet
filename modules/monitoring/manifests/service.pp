define monitoring::service(
    $description,
    $check_command,
    $host                  = $::hostname,
    $retries               = 3,
    $group                 = undef,
    $ensure                = present,
    $critical              = false,
    $passive               = false,
    $freshness             = 36000,
    $normal_check_interval = 1,
    $retry_check_interval  = 1,
    $contact_group         = hiera('contactgroups', 'admins'),
    $config_dir            = '/etc/nagios',
)
{
    # the list of characters is the default for illegal_object_name_chars
    # nagios/icinga option
    $description_safe = regsubst($description, '[`~!$%^&*"|\'<>?,()=]', '-', 'G')

    if ! $host {
        fail("Parameter ${host} not defined!")
    }
    $cluster_name = hiera('cluster', $cluster)
    $servicegroups = $group ? {
        /.+/    => $group,
        default => hiera('nagios_group',"${cluster_name}_${::site}")
    }

    $notification_critical = $critical ? {
        true    => 240,
        default => 0,
    }

    # If a service is set to critical and
    # paging is not disabled for this machine in hiera,
    # then use the "sms" contact group which creates pages.
    $do_paging = hiera('do_paging', true)

    case $critical {
        true: {
            case $do_paging {
                true:    { $contact_critical = "${contact_group},sms,admins" }
                default: { $contact_critical = "${contact_group},admins" }
            }
        }
        default: { $contact_critical = $contact_group }
    }

    $is_active = $passive ? {
        true    => 0,
        default => 1,
    }

    $check_volatile = $passive ? {
        true    => 1,
        default => 0,
    }

    $check_fresh = $passive ? {
        true    => 1,
        default => 0,
    }

    $is_fresh = $passive ? {
        true    => $freshness,
        default => undef,
    }

    # Export the nagios service instance
    @@nagios_service { "${::hostname} ${title}":
        ensure                 => $ensure,
        target                 => "${config_dir}/puppet_checks.d/${host}.cfg",
        host_name              => $host,
        servicegroups          => $servicegroups,
        service_description    => $description_safe,
        check_command          => $check_command,
        max_check_attempts     => $retries,
        normal_check_interval  => $normal_check_interval,
        retry_check_interval   => $retry_check_interval,
        check_period           => '24x7',
        notification_interval  => $notification_critical,
        notification_period    => '24x7',
        notification_options   => 'c,r,f',
        contact_groups         => $contact_critical,
        passive_checks_enabled => 1,
        active_checks_enabled  => $is_active,
        is_volatile            => $check_volatile,
        check_freshness        => $check_fresh,
        freshness_threshold    => $is_fresh,
    }
}
