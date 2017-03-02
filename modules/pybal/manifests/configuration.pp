class pybal::configuration(
    $lvs_services,
    $lvs_class_hosts,
    $site,
    $config='http',
    $global_options={},
    $config_host="config-master.${site}.wmnet",
    $conftool_prefix = '/conftool/v1',
) {

    # Generate PyBal config file
    file { '/etc/pybal/pybal.conf':
        require => Package['pybal'],
        content => template("${module_name}/pybal.conf.erb");
        # do not notify => Service['pybal'] on purpose
    }

}
