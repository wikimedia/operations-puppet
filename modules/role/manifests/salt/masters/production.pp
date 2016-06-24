class role::salt::masters::production {

    $salt_state_roots    = { 'base' => ['/srv/salt'] }
    $salt_file_roots     = { 'base' => ['/srv/salt'] }
    $salt_pillar_roots   = { 'base' => ['/srv/pillars'] }
    $salt_module_roots   = { 'base' => ['/srv/salt/_modules'] }
    $salt_returner_roots = { 'base' => ['/srv/salt/_returners'] }

    class { 'salt::master':
        salt_runner_dirs    => ['/srv/runners'],
        salt_peer_run       => {
            'tin.eqiad.wmnet'       => ['deploy.*'],
            'mira.codfw.wmnet'      => ['deploy.*'],
            'palladium.eqiad.wmnet' => ['keys.*'],
        },
        salt_file_roots     => $salt_file_roots,
        salt_pillar_roots   => $salt_pillar_roots,
        salt_worker_threads => '30',
        salt_state_roots    => $salt_state_roots,
        salt_module_roots   => $salt_module_roots,
        salt_returner_roots => $salt_returner_roots,
    }

    class { 'salt::master::key':
        salt_master_pubkey_type => 'prod',
    }

    ferm::service { 'salt_master_job_publisher':
        proto  => 'tcp',
        port   => '4505',
        srange => '$PRODUCTION_NETWORKS',
    }

    ferm::service { 'salt_master_minion_returns':
        proto  => 'tcp',
        port   => '4506',
        srange => '$PRODUCTION_NETWORKS',
    }
}
