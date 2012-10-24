class solr::multicore {
  include solr::multicore::files

  exec { "setup-solr-multicore":
    path    => "/usr/sbin",
    require => [ Class['solr::multicore::files'], Class['solr::install'] ],
  }
}

class solr::multicore::files {
  file {
    "/var/lib/solr/cores":
      ensure => directory,
      owner => 'jetty',
      group => 'jetty',
      mode => 0700,
      require => Class['solr::install'];
    "/usr/sbin/create-solr-core":
      ensure => present,
      source => "puppet:///modules/solr/create-solr-core",
      owner => 'root',
      group => 'root',
      mode => 0544;
    "/usr/sbin/delete-solr-core":
      ensure => present,
      source => "puppet:///modules/solr/delete-solr-core",
      owner => 'root',
      group => 'root',
      mode => 0544;
    "/usr/sbin/setup-solr-multicore":
      ensure => present,
      source => "puppet:///modules/solr/setup-solr-multicore",
      owner => 'root',
      group => 'root',
      mode => 0544;
  }
}

