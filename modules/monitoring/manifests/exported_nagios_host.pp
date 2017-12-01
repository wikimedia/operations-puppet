# proxy to an exported nagios_host definition
# Used as a workaround of https://tickets.puppetlabs.com/browse/PUP-6698
define monitoring::exported_nagios_host (
    $ensure,
    $host_name,
    $address,
    $hostgroups,
    $check_command,
    $check_period,
    $max_check_attempts,
    $notification_interval,
    $notification_period,
    $notification_options,
    $contact_groups,
    $icon_image,
    $vrml_image,
    $statusmap_image,
    $parents=undef,
    $notifications_enabled='1',
) {
    @@nagios_host { $title:
        ensure                => $ensure,
        host_name             => $host_name,
        parents               => $parents,
        address               => $address,
        hostgroups            => $hostgroups,
        check_command         => $check_command,
        check_period          => $check_period,
        max_check_attempts    => $max_check_attempts,
        notifications_enabled => $notifications_enabled,
        contact_groups        => $contact_groups,
        notification_interval => $notification_interval,
        notification_period   => $notification_period,
        notification_options  => $notification_options,
        icon_image            => $icon_image,
        vrml_image            => $vrml_image,
        statusmap_image       => $statusmap_image,

    }
}
