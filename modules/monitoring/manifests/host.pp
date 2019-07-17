# === Define monitoring::host
# Exports the resource that monitors hosts in icinga/shinken
#
define monitoring::host (
    $ip_address            = $facts['ipaddress'],
    $os                    = $facts['operatingsystem'],
    $host_fqdn             = undef,
    $group                 = undef,
    $ensure                = present,
    $critical              = false,
    $parents               = undef,
    $contact_group         = hiera('contactgroups', 'admins'),
    $notifications_enabled = '1',
    ) {

    $nagios_address = $host_fqdn ? {
        undef   => $ip_address,
        default => $host_fqdn,
    }

    # Determine the hostgroup:
    # If defined in the declaration of resource, we use it;
    # If not, adopt the standard format
    $cluster_name = hiera('cluster', $::cluster)
    $hostgroup = $group ? {
        /.+/    => $group,
        default => hiera('nagios_group',"${cluster_name}_${::site}")
    }

    $real_contact_groups = $critical ? {
        true    => "${contact_group},sms,admins",
        default => $contact_group,
    }

    # Define the nagios host instance
    # The following if guard is there to ensure we only try to set per host
    # attributes in the case the host exports it's configuration. Since this
    # definition is also used for non-exported resources as well, this if guard
    # is required
    if $title == $::hostname {
        $image = $os ? {
            'Ubuntu'  => 'ubuntu',
            'Debian'  => 'debian',
            'Junos'   => 'juniper',
            default   => 'linux40'
        }
        $icon_image      = "vendors/${image}.png"
        $vrml_image      = "vendors/${image}.png"
        $statusmap_image = "vendors/${image}.gd2"
        # Allow overriding the parents of a device. This makes the exposed API
        # more consistent, even though it's doubtful we will ever use this
        # functionality in the case of an exported host
        if $parents {
            $real_parents = $parents
        } elsif ($facts['is_virtual'] == false) and $facts['lldp_parent'] {
            # Only set the (automatic) parent for physical hosts. We want to
            # still alert for each individual VM when the hosts die, as:
            # a) just a host DOWN alert for the VM node is too inconspicuous,
            # b) it's usually the case that VMs can be relocated to other nodes
            $real_parents = $facts['lldp_parent']
        } else {
            $real_parents = undef
        }
        # We have a BMC, and the BMC is configured and it has an IP address
        # We always monitor the BMC so never skip notifications
        if $facts['has_ipmi'] and $facts['ipmi_lan'] and 'ipaddress' in $facts['ipmi_lan'] {
            $mgmt_host = {
                "${title}.mgmt" => {
                    ensure                => $ensure,
                    host_name             => "${title}.mgmt",
                    address               => $facts['ipmi_lan']['ipaddress'],
                    hostgroups            => 'mgmt',
                    check_command         => 'check_ping!500,20%!2000,100%',
                    check_period          => '24x7',
                    max_check_attempts    => 2,
                    contact_groups        => "${contact_group},admins",
                    notification_interval => 0,
                    notification_period   => '24x7',
                    notification_options  => 'd,u,r,f',
                    icon_image            => undef,
                    vrml_image            => undef,
                    statusmap_image       => undef,
                }
            }
        } else {
            $mgmt_host = undef
        }
        # Populate a network related hostgroup for directly connected to switches
        # hosts
        if $facts['lldp_parent'] and $facts['lldp_parent'] =~ /asw|csw/ {
            $hostgroups = "${hostgroup},${facts['lldp_parent']}"
        } else {
            $hostgroups = $hostgroup
        }
    } else {
        $icon_image      = undef
        $vrml_image      = undef
        $statusmap_image = undef
        $real_parents    = $parents
        $mgmt_host = undef
        $hostgroups = $hostgroup
    }
    $host = {
        "${title}" => {
            ensure                => $ensure,
            host_name             => $title,
            parents               => $real_parents,
            address               => $nagios_address,
            hostgroups            => $hostgroups,
            check_command         => 'check_ping!500,20%!2000,100%',
            check_period          => '24x7',
            max_check_attempts    => 2,
            notifications_enabled => $notifications_enabled,
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
        $rtype = 'nagios_host'
    } else {
        $rtype = 'monitoring::exported_nagios_host'
    }
    create_resources($rtype, $host)
    if !empty($mgmt_host) {
        create_resources($rtype, $mgmt_host)
        # We always monitor the BMC so never skip notifications
        monitoring::service { "dns_${title}.mgmt":
            description           => "DNS ${title}.mgmt",
            host                  => "${title}.mgmt",
            check_command         => "check_fqdn!${title}.mgmt.${::site}.wmnet",
            notifications_enabled => '1',
            group                 => 'mgmt',
            check_interval        => 60,
            retry_interval        => 60,
            notes_url             => 'https://wikitech.wikimedia.org/wiki/Dc-operations/Hardware_Troubleshooting_Runbook',
        }
        monitoring::service { "ssh_${title}.mgmt":
            description           => "SSH ${title}.mgmt",
            host                  => "${title}.mgmt",
            check_command         => 'check_ssh',
            notifications_enabled => '1',
            group                 => 'mgmt',
            check_interval        => 60,
            retry_interval        => 60,
            notes_url             => 'https://wikitech.wikimedia.org/wiki/Dc-operations/Hardware_Troubleshooting_Runbook',
        }
    }
}
