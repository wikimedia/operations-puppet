define swift_new::storage::monitor_swift_daemon {
    include nrpe

    # nrpe::monitor_service will create
    # nrpe::check command definition and a
    # monitor_service definition which exports to nagios
    nrpe::monitor_service { $title:
        description  => $title,
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1: --ereg-argument-array='^/usr/bin/python /usr/bin/${title}'",
    }
}
