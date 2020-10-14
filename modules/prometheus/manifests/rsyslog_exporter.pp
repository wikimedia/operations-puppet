class prometheus::rsyslog_exporter (
    Wmflib::Ensure $ensure = present,
    String $listen_address = ':9105',
) {
    package { 'prometheus-rsyslog-exporter':
        # TODO: use $ensure after T210137 is complete
        ensure => '0.0.0+git20201008-1',
        notify => Service['rsyslog']
    }

    rsyslog::conf { 'exporter':
        ensure   => $ensure,
        content  => template("${module_name}/rsyslog_exporter.conf.erb"),
        priority => 10,
    }
}
