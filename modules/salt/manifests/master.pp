class salt::master(
  $salt_interface=undef,
  $salt_worker_threads=undef,
  $salt_runner_dirs=["/srv/runners"],
  $salt_file_roots={"base"=>["/srv/salt"]},
  $salt_pillar_roots={"base"=>["/srv/pillar"]},
  $salt_ext_pillar={},
  $salt_reactor_root="/srv/reactors",
  $salt_reactor = {},
  $salt_peer={},
  $salt_peer_run={},
  $salt_nodegroups={}) {

  package { ["salt-master"]:
    ensure => present;
  }

  service { "salt-master":
    ensure => running,
    enable => true,
    require => [Package["salt-master"]];
  }

  file { "/etc/salt/master":
    content => template("salt/master.erb"),
    owner => root,
    group => root,
    mode => 0444,
    notify => Service["salt-master"],
    require => [Package["salt-master"]];
  }

  file { $salt_runner_dirs:
    ensure => directory,
    mode => 0755,
    owner => root,
    group => root;
  }

  file { $salt_reactor_root:
    ensure => directory,
    mode => 0755,
    owner => root,
    group => root;
  }

}
