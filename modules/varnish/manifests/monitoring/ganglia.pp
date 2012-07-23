class varnish::monitoring::ganglia($varnish_instances=['']) {
  file { '/usr/lib/ganglia/python_modules/varnish.py':
      source  => 'puppet:///files/ganglia/plugins/varnish.py',
      require => File['/usr/lib/ganglia/python_modules'],
      notify  => Service['gmond'],
  }

  file { '/etc/ganglia/conf.d/varnish.pyconf':
      content => template('ganglia/plugins/varnish.pyconf.erb'),
      require => File['/etc/ganglia/conf.d'],
      notify  => Service['gmond'],
  }
}
