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

    # defaults to "performance"
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

    # TODO: check this for false positives and then consider making it page
    monitoring::check_prometheus { 'excessive-lvs-rx-traffic':
        description     => 'Excessive RX traffic on an LVS (units megabits/sec)',
        warning         => 1600,
        critical        => 3200,
        query           => "scalar(sum(rate(node_network_receive_bytes_total{instance=~\"${::hostname}:.*\",device\\!~\"lo\"}[5m]))) * 8 / 1024 / 1024",
        prometheus_url  => "http://prometheus.svc.${::site}.wmnet/ops",
        dashboard_links => ["https://grafana.wikimedia.org/d/000000377/host-overview?var-server=${::hostname}&var-datasource=${::site} prometheus/ops"],
    }

    # Set up tagged interfaces to all subnets with real servers in them

    profile::lvs::tagged_interface {$tagged_subnets:
        interfaces => $vlan_data
    }

    # Apply needed interface tweaks

    create_resources(profile::lvs::interface_tweaks, $interface_tweaks)

}
