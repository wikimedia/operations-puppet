class deployment::salt_master(
    $state_dir='/srv/salt',
    $runner_dir='/srv/runners',
    $pillar_dir='/srv/pillars',
    $module_dir='/srv/salt/_modules',
    $returner_dir='/srv/salt/_returners',
    $repo_config,
    $deployment_config
) {

    file { "${state_dir}/deploy":
        ensure  => directory,
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        require => [File[$state_dir]],
    }

    file { "${state_dir}/top.sls":
        source  => 'puppet:///modules/deployment/states/top.sls',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        require => [File["${state_dir}/deploy"]],
    }

    file { "${state_dir}/deploy/sync_all.sls":
        source  => 'puppet:///modules/deployment/states/deploy/sync_all.sls',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        require => [File["${state_dir}/deploy"]],
    }

    file { "${runner_dir}/deploy.py":
        source  => 'puppet:///modules/deployment/runners/deploy.py',
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        require => File[$runner_dir],
    }

    file { "${pillar_dir}/deployment":
        ensure  => directory,
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        require => [File[$pillar_dir]],
    }

    file { "${pillar_dir}/deployment/repo_config.sls":
        # lint:ignore:arrow_alignment
        content => ordered_json({'repo_config' => $repo_config }),
        # lint:endignore
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        require => [File["${pillar_dir}/deployment"]],
    }

    file { "${pillar_dir}/deployment/deployment_config.sls":
        # lint:ignore:arrow_alignment
        content => ordered_json({'deployment_config' => $deployment_config}),
        # lint:endignore
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        require => [File["${pillar_dir}/deployment"]],
    }

    file { "${pillar_dir}/top.sls":
        content => template('deployment/pillars/top.sls.erb'),
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        require => [File[$pillar_dir]],
    }

    file { "${module_dir}/deploy.py":
        source  => 'puppet:///modules/deployment/modules/deploy.py',
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        require => [File[$module_dir]],
    }

    file { "${returner_dir}/deploy_redis.py":
        source  => 'puppet:///modules/deployment/returners/deploy_redis.py',
        mode    => '0555',
        owner   => 'root',
        group   => 'root',
        require => [File[$returner_dir]],
    }

    # deprecated in T97509
    file { "${module_dir}/mwprof.py":
        ensure  => absent,
    }

    # If pillars or modules change, we need to sync them with the minions
    exec { 'refresh_deployment_pillars':
        command     => "/usr/bin/salt -C 'G@deployment_server:true or G@deployment_target:*' saltutil.refresh_pillar",
        subscribe   => [File["${pillar_dir}/deployment/deployment_config.sls"],
                        File["${pillar_dir}/deployment/repo_config.sls"],
                        File[$pillar_dir]],
        refreshonly => true,
        require     => [Package['salt-master']],
    }

    exec { 'deployment_server_init':
        command     => "/usr/bin/salt -G 'deployment_server:true' deploy.deployment_server_init",
        subscribe   => [Exec['refresh_deployment_pillars']],
        refreshonly => true,
        require     => [File["${module_dir}/deploy.py"]],
    }

    exec { 'refresh_deployment_modules':
        command     => "/usr/bin/salt -C 'G@deployment_server:true or G@deployment_target:*' saltutil.sync_modules",
        subscribe   => File["${module_dir}/deploy.py"],
        refreshonly => true,
        require     => [Package['salt-master']],
    }

    exec { 'refresh_deployment_returners':
        command     => "/usr/bin/salt -C 'G@deployment_server:true or G@deployment_target:*' saltutil.sync_returners",
        subscribe   => [File["${returner_dir}/deploy_redis.py"]],
        refreshonly => true,
        require     => [Package['salt-master']],
  }
}
