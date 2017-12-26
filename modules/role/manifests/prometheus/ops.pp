# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
# filtertags: labs-project-monitoring
class role::prometheus::ops {
    system::role { 'prometheus::ops':
        description => 'Prometheus server (ops)',
    }

    include ::standard
    include ::profile::base::firewall
    include ::profile::prometheus::ops
    include ::prometheus::blackbox_exporter
    include ::rsync::server
}
