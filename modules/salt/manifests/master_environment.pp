define salt::master_environment($salt_file_roots, $salt_pillar_roots) {

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

}
