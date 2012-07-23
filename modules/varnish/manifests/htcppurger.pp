class varnish::htcppurger($varnish_instances=['localhost:80']) {
  Class[varnish::packages] -> Class[varnish::htcppurger]

  systemuser { 'varnishhtcpd':
    name          => 'varnishhtcpd',
    default_group => 'varnishhtcpd',
    home          => '/var/lib/varnishhtcpd'
  }

  $packages = ['liburi-perl', 'liblwp-useragent-determined-perl']

  package { $packages:
    ensure => latest,
  }

  file { '/usr/local/bin/varnishhtcpd':
    ensure  => present,
    source  => 'puppet:///modules/varnish/varnishhtcpd',
    owner   => root,
    group   => root,
    mode    => '0555',
  }
  file { '/etc/default/varnishhtcpd':
    ensure  => present,
    owner   => root,
    group   => root,
    mode    => '0444',
    content => inline_template('DAEMON_OPTS="--user=varnishhtcpd --group=varnishhtcpd --mcast_address=239.128.0.112<% varnish_instances.each do |inst| -%> --cache=<%= inst %><% end -%>"'),
  }

  upstart_job { 'varnishhtcpd':
    install => true,
  }

  service { 'varnishhtcpd':
    ensure   => running,
    require  => [
      File['/usr/local/bin/varnishhtcpd'],
      File['/etc/default/varnishhtcpd'],
      Package[$packages],
      Systemuser[varnishhtcpd],
      Upstart_job[varnishhtcpd]
    ],
    provider => upstart,
  }

  nrpe::monitor_service { 'varnishhtcpd':
    description  => 'Varnish HTCP daemon',
    nrpe_command => '/usr/lib/nagios/plugins/check_procs -c 1:1 -u varnishhtcpd -a "varnishhtcpd worker"',
  }
}
