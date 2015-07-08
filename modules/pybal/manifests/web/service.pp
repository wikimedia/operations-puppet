# prints all the pybal
define pybal::web::service($config) {
    $service_config = $config[$name]
    $dcs = $service_config['datacenters']
    $cluster = $service_config['conftool']['cluster']
    $service = $service_config['conftool']['service']
    pybal::conf_file { $dcs:
        pool_name => $name,
        cluster   => $cluster,
        service   => $service,
        basedir   => $::pybal::web::conftool_dir,
    }

}
