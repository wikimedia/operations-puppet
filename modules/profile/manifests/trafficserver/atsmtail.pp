define profile::trafficserver::atsmtail(
    String $instance_name,
    Stdlib::Absolutepath $atsmtail_progs,
    Stdlib::Port::User $atsmtail_port,
    Systemd::Servicename $wanted_by,
    String $mtail_args = '',
) {
    systemd::service { "atsmtail@${instance_name}":
        ensure  => present,
        restart => true,
        content => systemd_template('atsmtail@'),
    }
}
