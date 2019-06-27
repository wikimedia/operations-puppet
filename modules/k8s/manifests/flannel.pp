class k8s::flannel(
    String $etcd_endpoints,
) {
    require_package('flannel')

    systemd::service { 'flannel':
        ensure  => present,
        content => systemd_template('flannel'),
        restart => true,
    }
}
