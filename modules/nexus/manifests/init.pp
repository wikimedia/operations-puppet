class nexus (
    $data_dir,
    $application_port,
) {

    class {'nexus::install':
        data_dir         => $data_dir,
        application_port => $application_port,
    }

    base::service_unit { 'nexus':
        ensure         => present,
        require        => Class['nexus::install'],
        refresh        => true,
        systemd        => true,
        service_params => {
            enable     => true,
            hasstatus  => true,
            hasrestart => true,
        },
    }

}
