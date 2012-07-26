class solr::install {
  package { "solr-jetty":
    ensure => present,
  }

  # For some reason running solr this way needs jdk
  package { "openjdk-6-jdk":
    ensure => present,
  }
}

class solr::config {
  File {
    owner => 'jetty',
    group => 'root',
    mode  => '0644'
  }

  file { "/etc/default/jetty":
    ensure  => present,
    source  => "puppet:///modules/solr/jetty",
    owner   => 'root',
    require => Class["solr::install"],
    notify  => Class["solr::service"],
  }

  file { "schema":
    ensure  => present,
    path    => "/etc/solr/conf/schema.xml",
    source  => "puppet:///modules/solr/schema.xml",
    require => Class["solr::install"],
    notify  => Class["solr::service"],
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
}

class solr {
  include solr::install, solr::config, solr::service
}
