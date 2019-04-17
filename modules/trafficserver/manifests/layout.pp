define trafficserver::layout(
  Stdlib::Absolutepath $base_path = '/srv/trafficserver',
  Stdlib::Absolutepath $prefix = "${base_path}/${title}",
  Stdlib::Absolutepath $exec_prefix = $prefix,
  Stdlib::Absolutepath $bindir = "${prefix}/bin",
  Stdlib::Absolutepath $sbindir = "${prefix}/sbin",
  Stdlib::Absolutepath $sysconfdir = "${prefix}/etc",
  Stdlib::Absolutepath $datadir = "${prefix}/cache",
  Stdlib::Absolutepath $includedir = "${prefix}/include",
  Stdlib::Absolutepath $libdir = '/usr/lib/trafficserver',
  Stdlib::Absolutepath $libexecdir = '/usr/lib/trafficserver/modules',
  Stdlib::Absolutepath $localstatedir = "${prefix}/var",
  Stdlib::Absolutepath $runtimedir = "${prefix}/var/run",
  Stdlib::Absolutepath $logdir = "${prefix}/var/log",
  Stdlib::Absolutepath $cachedir = "${prefix}/var/cache",
) {
    if !defined(File[$base_path]) {
        file { $base_path:
            ensure => directory,
            owner  => $trafficserver::user,
            mode   => '0755',
        }
    }

    file { "/etc/trafficserver/${title}-layout.yaml":
        ensure  => file,
        owner   => $trafficserver::user,
        mode    => '0400',
        content => template('trafficserver/layout.yaml.erb'),
        require => Package['trafficserver'],
    }

    exec { "bootstrap-${title}-ats-runroot":
        command => "/usr/bin/traffic_layout init --path ${prefix} --layout /etc/trafficserver/${title}-layout.yaml -a --copy-style=soft",
        creates => "${prefix}/runroot.yaml",
        require => File["/etc/trafficserver/${title}-layout.yaml"],
    }
}
