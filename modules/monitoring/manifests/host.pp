# === Define monitoring::host
# Exports the resource that monitors hosts in icinga/shinken
#
define monitoring::host (
    $ip_address    = $::ipaddress,
    $host_fqdn     = undef,
    $group         = undef,
    $ensure        = present,
    $critical      = false,
    $contact_group = hiera('contactgroups', 'admins')
    ) {

    $nagios_address = $host_fqdn ? {
        undef   => $ip_address,
        default => $host_fqdn,
    }

    # Determine the hostgroup:
    # If defined in the declaration of resource, we use it;
    # If not, adopt the standard format
    $cluster_name = hiera('cluster', $cluster)
    $hostgroup = $group ? {
        /.+/    => $group,
        default => hiera('nagios_group',"${cluster_name}_${::site}")
    }

    $is_critical = $critical ? {
        true    => "${contact_group},sms,admins",
        default => $contact_group,
    }

    # Export the nagios host instance
    @@nagios_host { $title:
        ensure                => $ensure,
        target                => '/etc/nagios/puppet_hosts.cfg',
        host_name             => $title,
        address               => $nagios_address,
        hostgroups            => $hostgroup,
        check_command         => 'check_ping!500,20%!2000,100%',
        check_period          => '24x7',
        max_check_attempts    => 2,
        contact_groups        => $is_critical,
        notification_interval => 0,
        notification_period   => '24x7',
        notification_options  => 'd,u,r,f',
    }

    if $title == $::hostname {
        $image = $::operatingsystem ? {
            'Ubuntu'  => 'ubuntu',
            'Debian'  => 'debian',
            default   => 'linux40'
        }

        # Couple it with some hostextinfo
        @@nagios_hostextinfo { $title:
            ensure          => $ensure,
            target          => '/etc/nagios/puppet_hostextinfo.cfg',
            host_name       => $title,
            notes           => $title,
            icon_image      => "base/${image}.png",
            vrml_image      => "base/${image}.png",
            statusmap_image => "base/${image}.gd2",
        }
    }
}
