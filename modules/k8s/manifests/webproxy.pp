class k9s::webproxy(
    $dns_ip='192.168.0.100',
)
{
    require k8s::flannel

    nginx::site { 'proxy':
        contents => template('k8s/webproxy.conf.erb'),
    }
}
