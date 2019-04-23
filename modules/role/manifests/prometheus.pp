class role::prometheus {
    system::role { 'prometheus::server':  }
    include ::role::prometheus::ops
    include ::role::prometheus::global
    include ::role::prometheus::services
    include ::role::prometheus::analytics
    include ::role::prometheus::k8s
    include ::conftool::scripts # lint:ignore:wmf_styleguide

    include ::profile::standard
    # TODO: use role::lvs::realserver instead
    include ::lvs::realserver

    class { '::httpd':
        modules => ['proxy', 'proxy_http'],
    }

    interface::add_ip6_mapped { 'main': }
}
