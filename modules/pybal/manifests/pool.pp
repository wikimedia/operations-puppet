define pybal::pool($lvs_services={}) {
    $service_config = $lvs_services[$name]

    # this check should only exist for as long as
    # we have clusters not using etcd.
    if has_key($service_config, 'conftool') {

        $cluster = $service_config['conftool']['cluster']
        $service = $service_config['conftool']['service']

        $watch_keys = ["/conftool/v1/pools/$::site/$cluster/$service/"]
        $tmpl = template('pybal/host-pool.tmpl.erb')

        confd::file{ "/etc/pybal/pools/$name":
            watch_keys => $watch_keys,
            content    => $tmpl,
            check      => '/usr/local/bin/pybal-eval-check',
            require    => File['/etc/pybal/pools'],
        }
   }
}
