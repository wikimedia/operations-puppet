class nexus (
    $data_dir,
    $application_port,
) {

    require nexus::install

    base::service_unit { 'nexus':
        ensure         => present,
        refresh        => true,
        systemd        => true,
        service_params => {
            enable     => true,
            hasstatus  => true,
            hasrestart => true,
        },
    }

}
