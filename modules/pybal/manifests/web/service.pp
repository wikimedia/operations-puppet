# prints all the pybal
define pybal::web::service($config) {
    $dc = inline_template("<%= @name.split('/')[0] %>")
    $service = inline_template("<%= @name.split('/')[1] %>")


    $service_config = $config[$service]
    if member($service_config['sites'], $dc) {
        $cluster = $service_config['conftool']['cluster']
        $service_name = $service_config['conftool']['service']

        $path = "${::pybal::web::pools_dir}/${name}"

        pybal::conf_file { $path:
            dc      => $dc,
            cluster => $cluster,
            service => $service_name,
            require => File[$::pybal::web::root_dir],
        }
    }
}
