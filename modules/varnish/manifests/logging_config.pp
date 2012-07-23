class varnish::logging_config {
  file { '/etc/default/varnishncsa':
    source => 'puppet:///modules/varnish/varnishncsa.default',
    owner  => root,
    group  => root,
    mode   => '0444',
  }

  nrpe::monitor_service { 'varnishncsa':
    description  => 'Varnish traffic logger',
    nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 3:3 -c 3:6 -C varnishncsa',
  }
}
