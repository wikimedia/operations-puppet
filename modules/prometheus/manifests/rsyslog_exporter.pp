define prometheus::rsyslog_exporter (
    Wmflib::Ensure       $ensure = present,
    Stdlib::IP::Address  $listen_address = $facts['wmflib']['is_container'] ? {
                                              true  => '0.0.0.0',
                                              false => $facts['networking']['ip'],
                                          },
    Stdlib::Port         $listen_port    = 9105,
    Optional[String]     $instance       = undef,
) {
    ensure_packages(['prometheus-rsyslog-exporter'])

    $safe_title = $title.regsubst('[^\w\-]', '_', 'G')

    rsyslog::conf { "exporter-${safe_title}":
        ensure   => $ensure,
        content  => template("${module_name}/rsyslog_exporter.conf.erb"),
        priority => 10,
        instance => $instance,
    }

    # Legacy name
    if !defined(Rsyslog::Conf['exporter']) {
        rsyslog::conf { 'exporter':
            ensure   => absent,
            priority => 10,
        }
    }
}
