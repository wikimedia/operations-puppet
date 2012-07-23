define varnish::logging(
  $listener_address,
  $port='8420',
  $cli_args='',
  $instance_name='frontend'
) {
  require varnish::packages
  require varnish::logging_config

  file { "/etc/init.d/varnishncsa-${name}":
    content => template('varnish/varnishncsa.init.erb'),
    owner   => root,
    group   => root,
    mode    => '0555',
    notify  => Service["varnishncsa-${name}"],
  }

  service { "varnishncsa-${name}":
    ensure    => running,
    require   => File["/etc/init.d/varnishncsa-${name}"],
    subscribe => File['/etc/default/varnishncsa'],
    pattern   => "/var/run/varnishncsa/varnishncsa-${name}.pid",
    hasstatus => false,
  }
}
