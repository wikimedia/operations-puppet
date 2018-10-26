class prometheus::rsyslog_exporter (
    Wmflib::Ensure $ensure = present,
    String $listen_address = ':9105',
) {
    package { 'prometheus-rsyslog-exporter':
        ensure => $ensure,
    }

    rsyslog::conf { 'exporter':
        ensure   => $ensure,
        content  => template("${module_name}/rsyslog_exporter.conf.erb"),
        priority => 10,
    }
}
