class mysql::apparmorservice {
  service { "apparmor":
    ensure => 'running',
  }
}

