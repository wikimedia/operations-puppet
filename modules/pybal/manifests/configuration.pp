class pybal::configuration(
    $global_options={},
    $lvs_services,
    $lvs_class_hosts,
    $site
) {

    # Generate PyBal config file
    file { '/etc/pybal/pybal.conf':
        require => Package['pybal'],
        content => template("${module_name}/pybal.conf.erb");
        # do not notify => Service['pybal'] on purpose
    }

}
