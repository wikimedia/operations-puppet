class profile::puppet_compiler(
  Stdlib::Fqdn $cloud_puppetmaster = lookup('profile::puppet_compiler::cloud_puppetmaster')
) {

  requires_realm( 'labs' )

  require profile::ci::slave::labs::common

  ferm::service {'puppet_compiler_web':
    ensure => 'present',
    proto  => 'tcp',
    port   => 'http',
    prio   => '30',
    srange => '$LABS_NETWORKS'
  }

  # delete output files older than a month (T222072)
  $output_dir = '/srv/jenkins-workspace/puppet-compiler/output'
  systemd::timer::job {'delete-old-output-files':
    ensure      => 'present',
    description => 'Clean up old PCC reports',
    command     => "/usr/bin/find ${output_dir} -ctime +31 -delete",
    user        => 'root',
    interval    => {'start' => 'OnUnitInactiveSec', 'interval' => 'daily'},
  }
  $large_cleanup_cmd = @("CLEANUP_CMD")
  /usr/bin/find ${output_dir} -mindepth 1 -maxdepth 1 -type d -ctime +7 -exec du -ks {} + |
   awk '\$1 >= 1000000 {print \$2}' |
   xargs rm -rf
  | CLEANUP_CMD
  systemd::timer::job {'delete-old-output-large-reports':
    ensure      => 'present',
    description => 'Clean up PCC reports older then 7 days and biger then 1G',
    command     => $large_cleanup_cmd,
    user        => 'root',
    interval    => {'start' => 'OnUnitInactiveSec', 'interval' => 'daily'},
  }

  class {'puppet_compiler': }
  include profile::puppet_compiler::postgres_database

  # Conftool + etcd are needed for the conftool function to work
  # do not bother with hiera here, for now.
  class { 'profile::conftool::client':
    srv_domain => 'puppet-diffs.eqiad.wmflabs',
    host       => '127.0.0.1',
    port       => 2379,
    namespace  => dirname('/conftool/v1'),
  }

  class {'openstack::puppet::master::enc':
    puppetmaster => $cloud_puppetmaster,
  }
}
