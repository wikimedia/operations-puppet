# == Class bigtop::alluxio
#
# Installs Alluxio packages (needed for Alluxio masters and workers).
# Use this in conjunction with bigtop::alluxio::master and bigtop::alluxio::worker
# classes to install the master and worker services
#
# == Parameters
#
class bigtop::alluxio(

  String $zookeeper_hosts                     = undef,
  String $alluxio_env_template                = 'bigtop/alluxio/alluxio-env.sh.erb',
  String $alluxio_site_properties_template    = 'bigtop/alluxio/alluxio-site.properties.erb',
  String $alluxio_log4j_template              = 'bigtop/alluxio/log4j.properties.erb',
  String $alluxio_metrics_properties_template = 'bigtop/alluxio/metrics.properties.erb',

  Hash $alluxio_properties                    = undef,

) {
  Class['bigtop::hadoop'] -> Class['bigtop::alluxio']

  # We create the user and group prior to installing the package, so that they are
  # assigned our standard uid/gid values.
  require bigtop::alluxio::user

  package {'alluxio':
      ensure => installed,
  }

  $config_directory = "/etc/alluxio/conf.${bigtop::hadoop::cluster_name}"

  # Create the $cluster_name based $config_directory.
  file { $config_directory:
    ensure  => 'directory',
    require => Package['alluxio'],
  }
  bigtop::alternative { 'alluxio-conf':
    link => '/etc/alluxio/conf',
    path => $config_directory,
  }

  file { "${config_directory}/alluxio-site.properties":
    content => template($alluxio_site_properties_template),
    mode    => '0444',
    owner   => 'root',
    group   => 'root',
    require => Package['alluxio'],
  }

  file { "${config_directory}/log4j.properties":
    content => template($alluxio_log4j_template),
    mode    => '0444',
    owner   => 'root',
    group   => 'root',
    require => Package['alluxio'],
  }

  file { "${config_directory}/metrics.properties":
      content => template($alluxio_metrics_properties_template),
      mode    => '0444',
      owner   => 'root',
      group   => 'root',
      require => Package['alluxio'],
  }

  file { "${config_directory}/alluxio-env.sh":
      content => template($alluxio_env_template),
      mode    => '0444',
      owner   => 'root',
      group   => 'root',
      require => Package['alluxio'],
  }
}
