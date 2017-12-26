# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
# filtertags: labs-project-monitoring
class role::prometheus::ops {
    system::role { 'prometheus::ops':
        description => 'Prometheus server (ops)',
    }

    include ::standard
    include ::base::firewall
    include ::profile::prometheus::ops
    include ::prometheus::blackbox_exporter
    # Move Prometheus metrics to new HW - T148408
    include rsync::server
}
