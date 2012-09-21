class deployment::salt_master($runner_dir="/srv/runners", $pillar_dir="/srv/pillars", $module_dir="/srv/salt/_modules", $deployment_servers=[], $deployment_minion_regex=".*", $deployment_repo_urls={}, $deployment_repo_regex={}, $deployment_repo_locations={}) {
  file {
    "${runner_dir}/deploy.py":
      content => template("deployment/runners/deploy.py.erb"),
      mode => 0555,
      owner => root,
      group => root,
      notify => [Service["salt-master"]],
      require => [File["${runner_dir}"], Service["salt-master"]];
    "${pillar_dir}/deployment":
      ensure => directory,
      mode => 555,
      owner => root,
      group => root,
      require => [File["${pillar_dir}"]];
    "${pillar_dir}/deployment/init.sls":
      content => template("deployment/pillars/deploy.sls.erb"),
      mode => 0444,
      owner => root,
      group => root,
      require => [File["${pillar_dir}/deployment"]];
    "${module_dir}/deploy.py":
      source => "puppet:///deployment/modules/deploy.py",
      mode => 0555,
      owner => root,
      group => root,
      require => [File["${module_dir}"]];
  }

  # If pillars or modules change, we need to sync them to the deployment hosts
  exec {
    "refresh_deployment_pillars":
      command => "/usr/bin/salt -P '${deployment_minion_regex}' saltutil.refresh_pillar",
      watch => [File["${pillar_dir}/deployment/init.sls"]],
      require => [Package["salt-master"]];
    "refresh_deployment_modules":
      command => "/usr/bin/salt -P '${deployment_minion_regex}' saltutil.sync_modules",
      watch => [File["${module_dir}/modules/deploy.py"]],
      require => [Package["salt-master"]];
  }
}
