# prints all the pybal
define pybal::web::service($config) {
    $service_config = $config[$name]
    $dcs = $service_config['datacenters']
    $cluster = $service_config['conftool']['cluster']
    $service = $service_config['conftool']['service']
    $keys = suffix($dcs, "/${cluster}/${service}")
    pybal::conf_file { $keys:
        pool_name => $name,
        basedir   => $::pybal::web::conftool_dir,
    }

}
