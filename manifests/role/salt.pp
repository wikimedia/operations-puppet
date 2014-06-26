class role::salt::masters::production {

    $salt_state_roots    = { 'base'=>['/srv/salt']}
    $salt_file_roots     = { 'base'=>['/srv/salt']}
    $salt_pillar_roots   = { 'base'=>['/srv/pillars']}
    $salt_module_roots   = { 'base'=>['/srv/salt/_modules']}
    $salt_returner_roots = { 'base'=>['/srv/salt/_returners']}

    class { 'salt::master':
        salt_runner_dirs    => ['/srv/runners'],
        salt_peer_run       => {
            'tin.eqiad.wmnet' => ['deploy.*'],
        },
        salt_file_roots     => $salt_file_roots,
        salt_pillar_roots   => $salt_pillar_roots,
        salt_worker_threads => '25',
    }

    salt::master_environment{ 'base':
        salt_state_roots    => $salt_state_roots,
        salt_file_roots     => $salt_file_roots,
        salt_pillar_roots   => $salt_pillar_roots,
        salt_module_roots   => $salt_module_roots,
        salt_returner_roots => $salt_returner_roots,
    }

}

# A salt master that manages all labs minions
class role::salt::masters::labs {

    $salt_state_roots    = { 'base' =>['/srv/salt']}
    $salt_file_roots     = { 'base' =>['/srv/salt']}
    $salt_pillar_roots   = { 'base' =>['/srv/pillars']}
    $salt_module_roots   = { 'base' =>['/srv/salt/_modules']}
    $salt_returner_roots = { 'base' =>['/srv/salt/_returners']}

    class { 'salt::master':
        salt_runner_dirs    => ['/srv/runners'],
        salt_file_roots     => $salt_file_roots,
        salt_pillar_roots   => $salt_pillar_roots,
        salt_worker_threads => '50',
    }

    class { 'salt::reactors':
        salt_reactor_options => { 'puppet_server' => 'virt0.wikimedia.org' },
    }

    salt::master_environment{ 'base':
        salt_state_roots    => $salt_state_roots,
        salt_file_roots     => $salt_file_roots,
        salt_pillar_roots   => $salt_pillar_roots,
        salt_module_roots   => $salt_module_roots,
        salt_returner_roots => $salt_returner_roots,
    }

}

# A salt master manages minions within a project
class role::salt::masters::labs::project_master {

    $salt_state_roots    = { 'base'=>['/srv/salt']}
    $salt_file_roots     = { 'base'=>['/srv/salt']}
    $salt_pillar_roots   = { 'base'=>['/srv/pillars']}
    $salt_module_roots   = { 'base'=>['/srv/salt/_modules']}
    $salt_returner_roots = { 'base'=>['/srv/salt/_returners']}

    class { 'salt::master':
        salt_runner_dirs    => ['/srv/runners'],
                # For simplicity of test/dev we trust all of labs
                # to run deploy module calls, but rely on security groups
                # to secure this.
        salt_peer_run       => {
            '.*.eqiad.wmflabs' => ['deploy.*'],
        },
        salt_file_roots     => $salt_file_roots,
        salt_pillar_roots   => $salt_pillar_roots,
        salt_worker_threads => '10',
    }

    salt::master_environment{ 'base':
        salt_state_roots    => $salt_state_roots,
        salt_file_roots     => $salt_file_roots,
        salt_pillar_roots   => $salt_pillar_roots,
        salt_module_roots   => $salt_module_roots,
        salt_returner_roots => $salt_returner_roots,
    }

}

class role::salt::minions {

    if ($::realm == 'labs') {
        if ( $::salt_master_override != undef ) {
            $salt_master = $::salt_master_override
        } else {
            $salt_master = $::site ? {
                'pmtpa' => ['virt0.wikimedia.org', 'virt1000.wikimedia.org'],
                'eqiad' => ['virt1000.wikimedia.org', 'virt0.wikimedia.org'],
            }
        }
        if ( $::salt_master_finger_override != undef ) {
            $salt_master_finger = $::salt_master_finger_override
        } else {
            $salt_master_finger = 'c5:b1:35:45:3e:0a:19:70:aa:5f:3a:cf:bf:a0:61:dd'
        }
        $salt_client_id = $dc
        $salt_grains = {
            'instanceproject' => $instanceproject,
            'realm'           => $::realm,
            'site'            => $::site,
            'cluster'         => $cluster,
        }
    } else {
        ## Disabling multi-master salt for now, until synchronization
        ## issues are handled for puppet managing salt.
        ## When minions fetch modules/returners/pillars/etc. it's necessary
        ## for both salt masters to have the same sets of data or
        ## inconsistencies can occur.
        # $salt_master = $site ? {
        #   "pmtpa" => [ "sockpuppet.pmtpa.wmnet", "palladium.eqiad.wmnet" ],
        #   "eqiad" => [ "palladium.eqiad.wmnet", "sockpuppet.pmtpa.wmnet" ],
        # }
        $salt_master = 'palladium.eqiad.wmnet'
        $salt_client_id = $::fqdn
        $salt_grains = {
            'realm'   => $::realm,
            'site'    => $::site,
            'cluster' => $cluster,
        }
        $salt_master_finger = 'f6:1d:a7:1f:7e:12:10:40:75:d5:73:af:0c:be:7d:7c'
    }

    class { 'salt::minion':
        salt_master        => $salt_master,
        salt_client_id     => $salt_client_id,
        salt_grains        => $salt_grains,
        salt_master_finger => $salt_master_finger,
        salt_dns_check     => 'False',
    }

}
