class prometheus::cadvisor_exporter(
    Wmflib::Ensure $ensure,
    Stdlib::Port $port,
) {
    package { 'cadvisor':
        ensure => $ensure,
    }

    systemd::service { 'cadvisor':
        content   => init_template('cadvisor', 'systemd_override'),
        override  => true,
        restart   => true,
        subscribe => Package['cadvisor'],
    }
}
