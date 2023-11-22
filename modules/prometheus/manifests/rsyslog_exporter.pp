class prometheus::rsyslog_exporter (
    Wmflib::Ensure       $ensure = present,
    Stdlib::IP::Address  $listen_address = $facts['wmflib']['is_container'] ? {
                                              true  => '0.0.0.0',
                                              false => $facts['networking']['ip'],
                                          },
    Stdlib::Port         $listen_port    = 9105,
    Stdlib::Absolutepath $base           = '/etc/rsyslog.d',
) {
    package { 'prometheus-rsyslog-exporter':
        ensure => $ensure,
    }

    rsyslog::conf { 'exporter':
        ensure   => $ensure,
        content  => template("${module_name}/rsyslog_exporter.conf.erb"),
        priority => 10,
        base     => $base,
    }
}
