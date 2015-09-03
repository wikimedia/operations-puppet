class k8s::webproxy(
    $dns_ip='192.168.0.100',
) {
    require k8s::flannel

    nginx::site { 'proxy':
        content => template('k8s/webproxy.conf.erb'),
    }
}
