# === Class profile::lvs
#
# Sets up a linux load-balancer.
#
class profile::lvs(
    Array[String] $tagged_subnets = lookup('profile::lvs::tagged_subnets'),
    Hash[String, Hash] $vlan_data = lookup('lvs::interfaces::vlan_data'),
    Hash[String, Hash] $interface_tweaks = lookup('profile::lvs::interface_tweaks'),
){
    require profile::lvs::configuration

    $services = wmflib::service::get_services_for_lvs($profile::lvs::configuration::lvs_class, $::site)

    ## Kernel setup

    # defaults to "performance"
    class { '::cpufrequtils': }

    # kernel-level parameters
    class { '::lvs::kernel_config': }

    ## LVS IPs setup
    # Obtain all the IPs configured for this class of load-balancers,
    # as an array.
    $service_ips = wmflib::service::get_ips_for_services($services, $::site)

    # Bind balancer IPs to the loopback interface
    class { '::lvs::realserver':
        realserver_ips => $service_ips
    }

    # Monitoring sysctl
    $rp_args = inline_template('<%= @interfaces.split(",").map{|x| "net.ipv4.conf.#{x.gsub(/[_:.]/,"/")}.rp_filter=0" if !x.start_with?("lo") }.compact.join(",") %>')
    nrpe::monitor_service { 'check_rp_filter_disabled':
        description  => 'Check rp_filter disabled',
        nrpe_command => "/usr/local/lib/nagios/plugins/check_sysctl ${rp_args}",
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Monitoring/check_rp_filter_disabled',
    }

    # Set up tagged interfaces to all subnets with real servers in them

    profile::lvs::tagged_interface {$tagged_subnets:
        interfaces => $vlan_data
    }

    # Apply needed interface tweaks

    create_resources(profile::lvs::interface_tweaks, $interface_tweaks)

}
