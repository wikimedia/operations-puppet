define salt::master_environment($salt_state_roots, $salt_file_roots, $salt_pillar_roots, $salt_module_roots, $salt_returner_roots) {

  file { $salt_state_roots[$title]:
    ensure => directory,
    mode => 0755,
    owner => root,
    group => root;
  }

  file { $salt_file_roots[$title]:
    ensure => directory,
    mode => 0755,
    owner => root,
    group => root;
  }

  file { $salt_pillar_roots[$title]:
    ensure => directory,
    mode => 0755,
    owner => root,
    group => root;
  }

  file { $salt_module_roots[$title]:
    ensure => directory,
    mode => 0755,
    owner => root,
    group => root;
  }

  file { $salt_returner_roots[$title]:
    ensure => directory,
    mode => 0755,
    owner => root,
    group => root;
  }

}
