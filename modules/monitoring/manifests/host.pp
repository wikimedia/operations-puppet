# === Define monitoring::host
# Exports the resource that monitors hosts in icinga/shinken
#
define monitoring::host (
    $ip_address = $::ipaddress,
    $group         = hiera('nagios_group', "${cluster}_${::site}"),
    $ensure        = present,
    $critical      = 'false',
    $contact_group = 'admins'
    ) {
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
        target               => "/etc/nagios/puppet_hosts.cfg",
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
            target          => "/etc/nagios/puppet_hostextinfo.cfg",
            host_name       => $title,
            notes           => $title,
            icon_image      => "${image}.png",
            vrml_image      => "${image}.png",
            statusmap_image => "${image}.gd2",
        }
    }
}
