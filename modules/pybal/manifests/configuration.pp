class pybal::configuration(
    $global_options={},
    $lvs_services,
    $lvs_class_hosts,
    $site) {

    # Generate PyBal config file
    file { '/etc/pybal/pybal.conf':
        require => Package['pybal'],
        content => template("${module_name}/pybal.conf.erb");
    }

    $service_keys = keys($lvs_services)
    pybal::pool {$service_keys:
        lvs_services => $lvs_services,
        lvs_class_hosts => $lvs_class_hosts
    }
}
