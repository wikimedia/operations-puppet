class solr::multicore {
  include solr::multicore::files
  # We can't store this file in Puppet because Solr modifies it in runtime
  exec { "/usr/sbin/setup-solr-multicore":
    unless  => "grep -xqe '<solr persistent=\"true\" shareSchema=\"true\">' -- /etc/solr/solr.xml",
    #path    => "/bin:/usr/bin",
    require => [ Class['solr::multicore::files'], Class['solr:install'] ],
    notify  => Service['jetty'],
  }

class solr::multicore::files {
  file {
    "/var/lib/solr/cores":
      ensure => directory,
      owner => 'jetty',
      group => 'jetty',
      mode => 0700,
      require => Class['solr::install'];
    "/usr/sbin/add-solr-core":
      ensure => present,
      source => "puppet://modules/solr/add-solr-core",
      owner => 'root',
      group => 'root',
      mode => 0544;
    "/usr/sbin/remove-solr-core":
      ensure => present,
      source => "puppet://modules/solr/remove-solr-core",
      owner => 'root',
      group => 'root',
      mode => 0544;
    "/usr/sbin/setup-solr-multicore":
      ensure => present,
      source => "puppet://modules/solr/setup-solr-multicore",
      owner => 'root',
      group => 'root',
      mode => 0544;
  }
}

