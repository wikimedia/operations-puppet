class role::prometheus {
    system::role { 'prometheus::server':
        description => 'Prometheus server (main data centres)',
    }

    include ::role::prometheus::ops

    include ::profile::prometheus::k8s
    include ::profile::prometheus::analytics
    include ::profile::prometheus::services
    include ::profile::prometheus::global
    include ::conftool::scripts # lint:ignore:wmf_styleguide

    # We only have a staging cluster in eqiad, don't poll it from both DCs
    if $::site == 'eqiad' {
        include ::profile::prometheus::k8s::staging
    }

    include ::profile::standard
    include ::profile::base::firewall

    # TODO: use profile::lvs::realserver instead
    include ::lvs::realserver

    class { '::httpd':
        modules => ['proxy', 'proxy_http'],
    }
}
