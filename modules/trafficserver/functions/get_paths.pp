function trafficserver::get_paths(Boolean $default_instance, String $instance_name) >> Hash {
    $libdir = '/usr/lib/trafficserver'
    $libexecdir = "${libdir}/modules"
    if $default_instance { # debian layout -- https://github.com/apache/trafficserver/blob/master/config.layout
      $base_path = undef
      $prefix = '/usr'
      $exec_prefix = $prefix
      $sysconfdir = '/etc/trafficserver'
      $datadir = '/var/cache/trafficserver'
      $localstatedir = '/var/run'
      $runtimedir = '/var/run/trafficserver'
      $logdir = '/var/log/trafficserver'
    } else {
      $base_path = '/srv/trafficserver'
      $prefix = "${base_path}/${instance_name}"
      $exec_prefix = $prefix
      $sysconfdir = "${prefix}/etc"
      $datadir = "${prefix}/var/cache"
      $localstatedir = "${prefix}/var"
      $runtimedir = "${prefix}/var/run"
      $logdir = "${prefix}/var/log"
    }

    $bindir = "${exec_prefix}/bin"
    $sbindir = "${exec_prefix}/sbin"
    $includedir = "${prefix}/include"
    $cachedir = $datadir

    $paths = {
        base_path     => $base_path,
        prefix        => $prefix,
        exec_prefix   => $exec_prefix,
        bindir        => $bindir,
        sbindir       => $sbindir,
        sysconfdir    => $sysconfdir,
        datadir       => $datadir,
        includedir    => $includedir,
        libdir        => $libdir,
        libexecdir    => $libexecdir,
        localstatedir => $localstatedir,
        runtimedir    => $runtimedir,
        logdir        => $logdir,
        cachedir      => $cachedir,
        records       => "${sysconfdir}/records.config",
        ssl_multicert => "${sysconfdir}/ssl_multicert.config",
    }
}
