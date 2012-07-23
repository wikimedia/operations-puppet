define varnish::instance(
  $name='',
  $vcl = '',
  $port='80',
  $admin_port='6083',
  $storage='-s malloc,1G',
  $backends=[],
  $directors={},
  $director_type='hash',
  $vcl_config,
  $backend_options,
  $enable_geoiplookup=false,
  $wikimedia_networks=[],
  $xff_sources=[]) {

  include varnish::common

  if $name == '' {
    $instancesuffix = ''
    $extraopts = ''
  }
  else {
    $instancesuffix = "-${name}"
    $extraopts = "-n ${name}"
  }

  # Initialize variables for templates
  $varnish_port = $port
  $varnish_admin_port = $admin_port
  $varnish_storage = $storage
  $varnish_enable_geoiplookup = $enable_geoiplookup
  $varnish_backends = $backends
  $varnish_directors = $directors
  $varnish_backend_options = $backend_options

  # Install VCL include files shared by all instances
  require 'varnish::common-vcl'

  file { "/etc/init.d/varnish${instancesuffix}":
    content => template('varnish/varnish.init.erb'),
    mode    => '0555',
  }
  file { "/etc/default/varnish${instancesuffix}":
    content => template('varnish/varnish-default.erb'),
    mode    => '0444',
  }
  file { "/etc/varnish/${vcl}.inc.vcl":
    content => template("varnish/${vcl}.inc.vcl.erb"),
    mode    => '0444',
    notify  => Exec["load-new-vcl-file${instancesuffix}"],
  }
  file { "/etc/varnish/wikimedia_${vcl}.vcl":
    content => template('varnish/wikimedia.vcl.erb'),
    mode    => '0444',
    require => File["/etc/varnish/${vcl}.inc.vcl"],
  }

  service { "varnish${instancesuffix}":
    ensure    => running,
    require   => [
      File[
        "/etc/default/varnish${instancesuffix}",
        "/etc/init.d/varnish${instancesuffix}",
        "/etc/varnish/${vcl}.inc.vcl",
        "/etc/varnish/wikimedia_${vcl}.vcl"
      ],
      Mount['/var/lib/varnish']
    ],
    hasstatus => false,
    pattern   => "/var/run/varnishd${instancesuffix}.pid",
    subscribe => Package[varnish],
  }

  exec { "load-new-vcl-file${instancesuffix}":
    require     => [
      Service["varnish${instancesuffix}"],
      File["/etc/varnish/wikimedia_${vcl}.vcl"]
    ],
    subscribe   => File["/etc/varnish/wikimedia_${vcl}.vcl"],
    command     => "/usr/share/varnish/reload-vcl $extraopts",
    path        => '/bin:/usr/bin',
    refreshonly => true,
  }

  monitor_service { "varnish http ${title}":
    description   => "Varnish HTTP ${title}",
    check_command => "check_http_generic!varnishcheck!${port}"
  }

  # Restart gmond if this varnish instance has been (re)started later
  # than gmond was started
  exec { "restart gmond for varnish${instancesuffix}":
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    command => '/bin/true',
    onlyif  => "test /var/run/varnishd${instancesuffix}.pid -nt /var/run/gmond.pid",
    notify  => Service['gmond'],
  }
}
