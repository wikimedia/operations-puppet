class deployment::salt_master(
  $state_dir="/srv/salt",
  $runner_dir="/srv/runners",
  $pillar_dir="/srv/pillars",
  $module_dir="/srv/salt/_modules",
  $returner_dir="/srv/salt/_returners",
  $repo_config,
  $deployment_config
  ) {
  file {
    "/etc/salt/deploy_runner.conf":
      content => template("deployment/deploy_runner.conf.erb"),
      mode => 0444,
      owner => root,
      group => root,
      require => [Package["salt-master"]];
    "${state_dir}/deploy":
      ensure => directory,
      mode => 0555,
      owner => root,
      group => root,
      require => [File["${state_dir}"]];
    "${state_dir}/top.sls":
      source => "puppet:///deployment/states/top.sls",
      mode => 0444,
      owner => root,
      group => root,
      require => [File["${state_dir}/deploy"]];
    "${state_dir}/deploy/sync_all.sls":
      source => "puppet:///deployment/states/deploy/sync_all.sls",
      mode => 0444,
      owner => root,
      group => root,
      require => [File["${state_dir}/deploy"]];
    "${runner_dir}/deploy.py":
      source => "puppet:///deployment/runners/deploy.py",
      mode => 0555,
      owner => root,
      group => root,
      require => File["${runner_dir}"];
    "${pillar_dir}/deployment":
      ensure => directory,
      mode => 0555,
      owner => root,
      group => root,
      require => [File["${pillar_dir}"]];
    "${pillar_dir}/deployment/repo_config.sls":
      content => ordered_json($repo_config),
      mode => 0444,
      owner => root,
      group => root,
      require => [File["${pillar_dir}/deployment"]];
    "${pillar_dir}/deployment/deployment_config.sls":
      content => ordered_json($deployment_config),
      mode => 0444,
      owner => root,
      group => root,
      require => [File["${pillar_dir}/deployment"]];
    "${pillar_dir}/top.sls":
      content => template("deployment/pillars/top.sls.erb"),
      mode => 0444,
      owner => root,
      group => root,
      require => [File["${pillar_dir}"]];
    "${module_dir}/deploy.py":
      source => "puppet:///deployment/modules/deploy.py",
      mode => 0555,
      owner => root,
      group => root,
      require => [File["${module_dir}"]];
    "${returner_dir}/deploy_redis.py":
      source => "puppet:///deployment/returners/deploy_redis.py",
      mode => 0555,
      owner => root,
      group => root,
      require => [File["${returner_dir}"]];
    "${module_dir}/parsoid.py":
      source => "puppet:///deployment/modules/parsoid.py",
      mode => 0555,
      owner => root,
      group => root,
      require => [File["${module_dir}"]];
  }

  # If pillars or modules change, we need to sync them with the minions
  exec {
    "refresh_deployment_pillars":
      command => "/usr/bin/salt -C 'G@deployment_server:true or G@deployment_target:*' saltutil.refresh_pillar",
      subscribe => [File["${pillar_dir}/deployment/repo_config.sls"], File["${pillar_dir}/deployment/repo_config.sls"], File["${pillar_dir}"]],
      refreshonly => true,
      require => [Package["salt-master"]];
    "refresh_deployment_modules":
      command => "/usr/bin/salt -G 'deployment_target:*' saltutil.sync_modules",
      subscribe => [File["${module_dir}/deploy.py"],File["${module_dir}/parsoid.py"]],
      refreshonly => true,
      require => [Package["salt-master"]];
    "refresh_deployment_returners":
      command => "/usr/bin/salt -G 'deployment_target:*' saltutil.sync_returners",
      subscribe => [File["${returner_dir}/deploy_redis.py"]],
      refreshonly => true,
      require => [Package["salt-master"]];
  }
}
