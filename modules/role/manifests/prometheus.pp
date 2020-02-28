class role::prometheus {
    system::role { 'prometheus::server':  }
    include ::role::prometheus::ops
    include ::role::prometheus::global
    include ::role::prometheus::services
    include ::role::prometheus::analytics
    include ::profile::prometheus::k8s
    include ::conftool::scripts # lint:ignore:wmf_styleguide

    # We only have a staging cluster in eqiad, don't poll it from both DCs
    if $::site == 'eqiad' {
        include ::profile::prometheus::k8s::staging
    }

    include ::profile::standard
    # TODO: use profile::lvs::realserver instead
    include ::lvs::realserver

    class { '::httpd':
        modules => ['proxy', 'proxy_http'],
    }
}
