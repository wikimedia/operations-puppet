define profile::trafficserver::atsmtail(
    String $instance_name,
    Stdlib::Absolutepath $atsmtail_progs,
    Wmflib::UserIpPort $atsmtail_port,
) {
    systemd::service { "atsmtail@${instance_name}":
        ensure  => present,
        restart => true,
        content => systemd_template('atsmtail@'),
    }
}
