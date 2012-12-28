# = Class: solr
#
# This class installs/configures/manages Solr service.
#
# == Parameters:
#
# $schema::             Schema file for Solr (only one schema per instance supported)
# $replication_master:: Replication master, if this is current hostname, this server will be a master
# $monitor::            How to monitor this server:
#                       * "service" - just presence of Solr
#                       * "results" - whether Solr has some data in its index
#                       Any other input will disable monitoring
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

class solr::service($monitor) {
  service { "jetty":
    ensure => running,
    enable => true,
  }

  if ($monitor == "service") {
    monitor_service { "Solr":
      description => "Solr search engine",
      check_command => "check_http_url!{$::host}!http://{$::fqdn}:8983/solr/select/?q=*%3A*&start=0&rows=1&indent=on"
    }
  }
  elsif ($monitor == "results") {
    monitor_service { "Solr":
      description => "Solr search engine (with non-empty result set)",
      check_command => "check_http_url_for_string!{$::host}!http://{$::fqdn}:8983/solr/select/?q=*%3A*&start=0&rows=1&indent=on!'<str name=\"rows\">1</str>'"
    }
  }
}

class solr ($schema = undef, $replication_master = undef, $monitor = "service") {
  include solr::install
  class {
    "solr::config":
      schema => $schema,
      replication_master => $replication_master;
    "solr::service":
      monitor => $monitor;
  }
}
