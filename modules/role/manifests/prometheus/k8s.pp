# Uses the prometheus module and generates the specific configuration
# needed for WMF production
#
# filtertags: labs-project-monitoring
class role::prometheus::k8s {
    system::role { 'prometheus::k8s':
        description => 'Prometheus server (k8s)',
    }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::prometheus::k8s

    # We only have a staging cluster in eqiad, don't poll it from both DCs
    if $::site == 'eqiad' {
        include ::profile::prometheus::k8s::staging
    }
}
