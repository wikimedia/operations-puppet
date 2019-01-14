# Monitor single instance of Blazegraph
define wdqs::monitor::blazegraph_instance (
    Stdlib::Port $port,
    String $username,
    String $contact_groups,
) {
    nrpe::monitor_service { "WDQS_Local_Blazegraph_endpoint-${title}":
        description  => "Blazegraph Port for ${title}",
        nrpe_command => "/usr/lib/nagios/plugins/check_tcp -H 127.0.0.1 -p ${port}",
    }

    nrpe::monitor_service { "${title}-_process":
        description  => "Blazegraph process (${title})",
        nrpe_command => "/usr/lib/nagios/plugins/check_procs -c 1:1 -u ${username} --ereg-argument-array '^java .* --port ${port} .* blazegraph-service-.*war'",
    }

}
