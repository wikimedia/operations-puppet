# === Define monitoring::host
# Exports the resource that monitors hosts in icinga
#
define monitoring::host (
    Wmflib::Ensure         $ensure                = present,
    String                 $os                    = $facts['operatingsystem'],
    Boolean                $critical              = false,
    Stdlib::Host           $ip_address            = $facts['ipaddress'],
    Optional[Stdlib::Fqdn] $host_fqdn             = undef,
    Optional[String]       $contact_group         = undef,
    Optional[String]       $group                 = undef,
    Optional[String]       $parents               = undef,
    Optional[Boolean]      $notifications_enabled = undef,
){

    include monitoring
    $_contact_group          = pick($contact_group, $monitoring::contact_group)
    $mgmt_contact_group     = $monitoring::mgmt_contact_group
    $mgmt_parents           = $monitoring::mgmt_parents
    # Use pick default as it allows an undef default
    $_notifications_enabled = pick($notifications_enabled, $monitoring::notifications_enabled)
    $hostgroup              = pick($group, $monitoring::nagios_group)
    $nagios_address         = pick($host_fqdn, $ip_address)

    $real_contact_groups = $critical ? {
        # TODO: we should probably move this to the profile
        true    => "${_contact_group},sms,admins",
        default => $_contact_group,
    }

    # Define the nagios host instance
    # The following if guard is there to ensure we only try to set per host
    # attributes in the case the host exports it's configuration. Since this
    # definition is also used for non-exported resources as well, this if guard
    # is required
    if $title == $facts['hostname'] {
        $image = $os ? {
            'Junos'   => 'juniper',
            default   => 'debian'
        }
        $icon_image      = "vendors/${image}.png"
        $vrml_image      = "vendors/${image}.png"
        $statusmap_image = "vendors/${image}.gd2"
        # Allow overriding the parents of a device. This makes the exposed API
        # more consistent, even though it's doubtful we will ever use this
        # functionality in the case of an exported host
        if $parents {
            $real_parents = $parents
        } elsif ($facts['is_virtual'] == false) and $facts['lldp'] {
            # Only set the (automatic) parent for physical hosts. We want to
            # still alert for each individual VM when the hosts die, as:
            # a) just a host DOWN alert for the VM node is too inconspicuous,
            # b) it's usually the case that VMs can be relocated to other nodes
            #
            # Old Juniper switches advertise their short name, while new ones advertise their FQDN
            $real_parents = $facts['lldp']['parent'].split('\.')[0]
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
                    parents               => $mgmt_parents[$::site],
                    address               => $facts['ipmi_lan']['ipaddress'],
                    hostgroups            => 'mgmt',
                    check_command         => 'check_ping!500,20%!2000,100%',
                    check_period          => '24x7',
                    max_check_attempts    => 2,
                    contact_groups        => "${mgmt_contact_group},admins",
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
        if $facts['lldp'] and $facts['lldp']['parent'] =~ /asw|cloudsw|lsw/ {
            $hostgroups = "${hostgroup},${facts['lldp']['parent'].split('\.')[0]}"
        } else {
            $hostgroups = $hostgroup
        }
    } else {  # Network devices are defined in this section
        if $os == 'Junos' {
            $icon_image      = 'vendors/juniper.png'
            $vrml_image      = 'vendors/juniper.png'
            $statusmap_image = 'vendors/juniper.gd2'
        } else {
            $icon_image      = undef
            $vrml_image      = undef
            $statusmap_image = undef
        }
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
            notifications_enabled => $_notifications_enabled.bool2str('1', '0'),
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
            description           => 'DNS',
            host                  => "${title}.mgmt",
            check_command         => "check_fqdn!${title}.mgmt.${::site}.wmnet",
            notifications_enabled => true,
            group                 => 'mgmt',
            check_interval        => 60,
            retry_interval        => 60,
            notes_url             => 'https://wikitech.wikimedia.org/wiki/Dc-operations/Hardware_Troubleshooting_Runbook',
        }
        monitoring::service { "ssh_${title}.mgmt":
            description           => 'SSH',
            host                  => "${title}.mgmt",
            check_command         => 'check_ssh',
            notifications_enabled => true,
            group                 => 'mgmt',
            check_interval        => 60,
            retry_interval        => 60,
            notes_url             => 'https://wikitech.wikimedia.org/wiki/Dc-operations/Hardware_Troubleshooting_Runbook',
        }
    }
}
