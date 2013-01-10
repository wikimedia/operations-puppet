class deployment::salt_master($state_dir="/srv/salt", $runner_dir="/srv/runners", $pillar_dir="/srv/pillars", $module_dir="/srv/salt/_modules", $returner_dir="/srv/salt/_returners", $deployment_servers={}, $deployment_minion_regex=".*", $deployment_repo_urls={}, $deployment_repo_regex={}, $deployment_repo_locations={}, $deployment_repo_checkout_module_calls={}, $deployment_repo_checkout_submodules={}, $deployment_repo_dependencies = {}, $deployment_deploy_redis={}) {
  file {
    "${state_dir}/deploy":
      ensure => directory,
      mode => 0555,
      owner => root,
      group => root,
      require => [File["${state_dir}"]];
    "${state_dir}/deploy/sync_all.sls":
      source => "puppet:///deployment/states/sync_all.sls",
      mode => 0444,
      owner => root,
      group => root,
      require => [File["${state_dir}/deploy"]];
    "${runner_dir}/deploy.py":
      content => template("deployment/runners/deploy.py.erb"),
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
    "${pillar_dir}/deployment/init.sls":
      content => template("deployment/pillars/deploy.sls.erb"),
      mode => 0444,
      owner => root,
      group => root,
      require => [File["${pillar_dir}/deployment"]];
    ## Disable management of top pillar for now
    #"${pillar_dir}/top.sls":
    #  content => template("deployment/pillars/top.sls.erb"),
    #  mode => 0444,
    #  owner => root,
    #  group => root,
    #  require => [File["${pillar_dir}"]];
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

  # If pillars or modules change, we need to sync them to the deployment hosts
  exec {
    "refresh_deployment_pillars":
      command => "/usr/bin/salt -E '*' saltutil.refresh_pillar",
      subscribe => [File["${pillar_dir}/deployment/init.sls"], File["${pillar_dir}"]],
      refreshonly => true,
      require => [Package["salt-master"]];
    "refresh_deployment_modules":
      command => "/usr/bin/salt -E '*' saltutil.sync_modules",
      subscribe => [File["${module_dir}/deploy.py"],File["${module_dir}/parsoid.py"]],
      refreshonly => true,
      require => [Package["salt-master"]];
    "refresh_deployment_returners":
      command => "/usr/bin/salt -E '*' saltutil.sync_returners",
      subscribe => [File["${returner_dir}/deploy_redis.py"]],
      refreshonly => true,
      require => [Package["salt-master"]];
  }
}
