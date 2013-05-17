class salt::reactors(
  $salt_reactor_root="/srv/reactors",
  $salt_reactor_options={"puppet_server"=>"puppet"}) {

  file { "${salt_reactor_root}/auth.sls":
    content => template("salt/reactors/auth.sls.erb"),
    owner => root,
    group => root,
    mode => 0444,
    require => File[$salt_reactor_root];
  }
  file { "${salt_reactor_root}/key.sls":
    content => template("salt/reactors/key.sls.erb"),
    owner => root,
    group => root,
    mode => 0444,
    require => File[$salt_reactor_root];
  }
  file { "${salt_reactor_root}/minion_start.sls":
    content => template("salt/reactors/minion_start.sls.erb"),
    owner => root,
    group => root,
    mode => 0444,
    require => File[$salt_reactor_root];
  }
  file { "${salt_reactor_root}/puppet.sls":
    content => template("salt/reactors/puppet.sls.erb"),
    owner => root,
    group => root,
    mode => 0444,
    require => File[$salt_reactor_root];
  }
}
