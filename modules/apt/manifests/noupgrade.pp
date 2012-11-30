class apt::noupgrade {
  package { "update-manager-core":
    ensure => absent;
  }
}
