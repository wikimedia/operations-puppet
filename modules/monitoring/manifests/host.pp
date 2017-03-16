# === Define monitoring::host
# Exports the resource that monitors hosts in icinga/shinken
#
define monitoring::host (
    $ip_address    = $::main_ipaddress,
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
    # FIXME - top-scope var without namespace, will break in puppet 2.8
    # lint:ignore:variable_scope
    $cluster_name = hiera('cluster', $cluster)
    # lint:endignore
    $hostgroup = $group ? {
        /.+/    => $group,
        default => hiera('nagios_group',"${cluster_name}_${::site}")
    }

    $real_contact_groups = $critical ? {
        true    => "${contact_group},sms,admins",
        default => $contact_group,
    }

    # Export the nagios host instance
    if $title == $::hostname {
        $image = $::operatingsystem ? {
            'Ubuntu'  => 'ubuntu',
            'Debian'  => 'debian',
            default   => 'linux40'
        }
        $icon_image      = "vendors/${image}.png"
        $vrml_image      = "vendors/${image}.png"
        $statusmap_image = "vendors/${image}.gd2"
    } else {
        $icon_image      = undef
        $vrml_image      = undef
        $statusmap_image = undef
    }
    # TODO: Make this better by getting all LLDP peers on all physical (only!) interfaces
    # map() would have been great for this.
    if $facts['lldppeer_eth0'] {
        $parents = $facts['lldppeer_eth0']
    } else {
        $parents = undef
    }
    $host = {
        "${title}" => {
            ensure                => $ensure,
            host_name             => $title,
            parents               => $parents,
            address               => $nagios_address,
            hostgroups            => $hostgroup,
            check_command         => 'check_ping!500,20%!2000,100%',
            check_period          => '24x7',
            max_check_attempts    => 2,
            contact_groups        => $real_contact_groups,
            notification_interval => 0,
            notification_period   => '24x7',
            notification_options  => 'd,u,r,f',
            icon_image            => $icon_image,
            vrml_image            => $vrml_image,
            statusmap_image       => $statusmap_image,
        },
    }
    # This is a hack. We detect if we are running on the scope of an icinga
    # host and avoid exporting the resource if yes
    if defined(Class['icinga']) {
        create_resources(nagios_host, $host)
    } else {
        create_resources('@@nagios_host', $host)
    }
}
