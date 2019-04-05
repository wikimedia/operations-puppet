class profile::base::puppet(
  String           $puppetmaster  = lookup('puppetmaster'),
  Stdlib::Host     $ca_server     = lookup('puppet_ca_server'),
  Integer[1,59]    $interval      = lookup('profile::base::puppet::interval',
                                          {'default_value' => 30}),
  Optional[String] $dns_alt_names = lookup('profile::base::puppet::dns_alt_names',
                                          {'default_value' => undef}),
  String           $environment   = lookup('profile::base::puppet::environment',
                                          {'default_value' => 'production'}),
  # is the below paramater still used?
  Boolean $auto_puppetmaster_switching = lookup('profile::base::puppet::auto_puppetmaster_switching',
                                                {'default_value' => false}),
) {

  class { '::base::puppet':
      server                      => $puppetmaster,
      ca_server                   => $ca_server,
      dns_alt_names               => $dns_alt_names,
      environment                 => $environment,
      interval                    => $interval,
      auto_puppetmaster_switching => $auto_puppetmaster_switching,
  }
  class { '::puppet_statsd':
      statsd_host   => 'statsd.eqiad.wmnet',
      metric_format => 'puppet.<%= metric %>',
  }
  class { '::prometheus::node_puppet_agent': }
}
