# === Class profile::lvs
#
# Sets up a linux load-balancer.
#
class profile::lvs(
    $tagged_subnets = hiera('profile::lvs::tagged_subnets'),
    $vlan_data = hiera('lvs::interfaces::vlan_data'),
    $interface_tweaks = hiera('profile::lvs::interface_tweaks'),
){
    require ::lvs::configuration

    ## Kernel setup

    # defaults to "performance", Ubuntu default is "ondemand"
    class { '::cpufrequtils': }

    # kernel-level parameters
    class { '::lvs::kernel_config': }

    # Network interfaces setup
    interface::add_ip6_mapped { 'main': }

    ## LVS IPs setup
    # Obtain all the IPs configured for this class of load-balancers,
    # as a string. This is based on
    # $::lvs::configuration::lvs_grain_class
    # and
    # $::lvs::configuration::lvs_services
    $service_ips = template('profile/lvs/service_ips.erb')

    # Bind balancer IPs to the loopback interface
    class { '::lvs::realserver':
        realserver_ips => $service_ips
    }

    # Monitoring sysctl
    $rp_args = inline_template('<%= @interfaces.split(",").map{|x| "net.ipv4.conf.#{x.gsub(/[_:.]/,"/")}.rp_filter=0" if !x.start_with?("lo") }.compact.join(",") %>')
    nrpe::monitor_service { 'check_rp_filter_disabled':
        description  => 'Check rp_filter disabled',
        nrpe_command => "/usr/lib/nagios/plugins/check_sysctl ${rp_args}",
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Monitoring/check_rp_filter_disabled',
    }

    # Set up tagged interfaces to all subnets with real servers in them

    profile::lvs::tagged_interface {$tagged_subnets:
        interfaces => $vlan_data
    }

    # Apply needed interface tweaks

    create_resources(profile::lvs::interface_tweaks, $interface_tweaks)

}
