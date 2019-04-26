class profile::base::puppet(
  String           $puppetmaster  = lookup('puppetmaster'),
  String           $ca_server     = lookup('puppet_ca_server'),
  Integer[1,59]    $interval      = lookup('profile::base::puppet::interval',
                                          {'default_value' => 30}),
  Optional[String] $dns_alt_names = lookup('profile::base::puppet::dns_alt_names',
                                          {'default_value' => undef}),
  String           $environment   = lookup('profile::base::puppet::environment',
                                          {'default_value' => 'production'}),
  Integer[2,3]     $facter_major_version = lookup('profile::base::puppet::facter_major_version',
                                                  {'default_value' => 2}),
  Integer[4,5]     $puppet_major_version = lookup('profile::base::puppet::puppet_major_version',
                                                  {'default_value' => 4}),
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
      facter_major_version        => $facter_major_version,
      puppet_major_version        => $puppet_major_version,
      auto_puppetmaster_switching => $auto_puppetmaster_switching,
  }
  class { '::puppet_statsd':
      statsd_host   => 'statsd.eqiad.wmnet',
      metric_format => 'puppet.<%= metric %>',
  }
  class { '::prometheus::node_puppet_agent': }
}
