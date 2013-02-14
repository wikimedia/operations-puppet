class salt_reactors($salt_reactor_root, $salt_reactor_options={'puppet_server'=>'puppet'}) {
  file { "${salt_reactor_root}/auth.sls":
    content => template("salt_puppet/auth.sls.erb"),
    owner => root,
    group => root,
    mode => 0444,
    require => File[$salt_reactor_root];
  }
  file { "${salt_reactor_root}/key.sls":
    content => template("salt_puppet/key.sls.erb"),
    owner => root,
    group => root,
    mode => 0444,
    require => File[$salt_reactor_root];
  }
  file { "${salt_reactor_root}/minion_start.sls":
    content => template("salt_puppet/minion_start.sls.erb"),
    owner => root,
    group => root,
    mode => 0444,
    require => File[$salt_reactor_root];
  }
  file { "${salt_reactor_root}/puppet.sls":
    content => template("salt_puppet/puppet.sls.erb"),
    owner => root,
    group => root,
    mode => 0444,
    require => File[$salt_reactor_root];
  }
}
