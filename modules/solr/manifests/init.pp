# = Class: solr
#
# This class installs/configures/manages Solr service.
#
# == Parameters:
#
# $schema::             Schema file for Solr (only one schema per instance supported)
# $replication_master:: Replication master, if this is current hostname, this server will be a master
#
# == Sample usage:
#
#   class { "solr":
#     schema => "puppet:///modules/solr/schema-ttmserver.xml",
#   }

class solr::install {
  package { "solr-jetty":
    ensure => present,
  }

  # For some reason running solr this way needs jdk
  package { "openjdk-6-jdk":
    ensure => present,
  }
}

class solr::config ( $schema = undef, $replication_master = undef ) {
  File {
    owner => 'jetty',
    group => 'root',
    mode  => '0644',
    require => Class["solr::install"],
    notify  => Class["solr::service"],
  }

  file {
    "/etc/default/jetty":
      ensure  => present,
      source  => "puppet:///modules/solr/jetty",
      owner   => 'root';
    "/etc/solr/conf/solrconfig.xml":
      ensure  => present,
      owner   => 'root',
      content => template("solr/solrconfig.xml.erb"),
  }

  if $schema != undef {
    file { "schema":
      ensure  => present,
      path    => "/etc/solr/conf/schema.xml",
      source  => $schema,
    }
  }

  # Apparently there is a bug in the debian package
  # and the default symlink points to non-existing dir
  # webapp instead of web
  file { "/usr/share/jetty/webapps/solr":
    ensure => "link",
    target => "/usr/share/solr/web",
  }
}

class solr::service {
  service { "jetty":
    ensure => running,
    enable => true,
  }

  cron { "delete-old-jetty-logs":
    command => "find /var/log/jetty/* -mtime +7 -delete",
    user => "root",
    hour => 0,
    minute => 0,
    ensure => present,
  }
}

class solr ($schema = undef, $replication_master = undef) {
  include solr::install,
    solr::service

  class { "solr::config":
    schema => $schema,
    replication_master => $replication_master,
  }
}
