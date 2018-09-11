define monitoring::service(
    $description,
    $check_command,
    $notes_url,
    $host                  = $::hostname,
    $retries               = 3,
    $group                 = undef,
    $ensure                = present,
    $critical              = false,
    $passive               = false,
    $freshness             = 36000,
    $check_interval        = 1,
    $retry_interval        = 1,
    $contact_group         = hiera('contactgroups', 'admins'),
    $config_dir            = '/etc/nagios',
    $event_handler         = undef,
    $notifications_enabled = $::profile::base::notifications_enabled,
)
{
    # the list of characters is the default for illegal_object_name_chars
    # nagios/icinga option
    $description_safe = regsubst($description, '[`~!$%^&*"|\'<>?,()=]', '-', 'G')

    if ! $host {
        fail("Parameter ${host} not defined!")
    }

    $cluster_name = hiera('cluster', $::cluster)

    $servicegroups = $group ? {
        /.+/    => $group,
        default => hiera('nagios_group',"${cluster_name}_${::site}")
    }

    $notification_interval = $critical ? {
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
                true:    { $real_contact_groups = "${contact_group},sms,admins" }
                default: { $real_contact_groups = "${contact_group},admins" }
            }
        }
        default: { $real_contact_groups = $contact_group }
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

    # Safeguard against notifications enabled not being defined due to class
    # declarations
    if $notifications_enabled {
        $real_notifications_enabled = $notifications_enabled
    } else {
        $real_notifications_enabled = '1'
    }

    # the nagios service instance
    $service = {
        "${::hostname} ${title}" => {
            ensure                 => $ensure,
            host_name              => $host,
            servicegroups          => $servicegroups,
            service_description    => $description_safe,
            check_command          => $check_command,
            max_check_attempts     => $retries,
            check_interval         => $check_interval,
            retry_interval         => $retry_interval,
            check_period           => '24x7',
            notification_interval  => $notification_interval,
            notification_period    => '24x7',
            notification_options   => 'c,r,f',
            notifications_enabled  => $real_notifications_enabled,
            contact_groups         => $real_contact_groups,
            passive_checks_enabled => 1,
            active_checks_enabled  => $is_active,
            is_volatile            => $check_volatile,
            check_freshness        => $check_fresh,
            freshness_threshold    => $is_fresh,
            event_handler          => $event_handler,
            notes_url              => $notes_url,
        },
    }
    # This is a hack. We detect if we are running on the scope of an icinga
    # host and avoid exporting the resource if yes
    if defined(Class['icinga']) {
        create_resources(nagios_service, $service)
    } else {
        create_resources('monitoring::exported_nagios_service', $service)
    }
}
