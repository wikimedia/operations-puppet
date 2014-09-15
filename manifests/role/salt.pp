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
    if $::realm == 'labs' {
        $labs_masters  = [ 'virt1000.wikimedia.org', 'virt0.wikimedia.org' ]
        $labs_finger   = 'c5:b1:35:45:3e:0a:19:70:aa:5f:3a:cf:bf:a0:61:dd'
        $master        = pick($::salt_master_override, $labs_masters)
        $master_finger = pick($::salt_master_finger_override, $labs_finger)
        $client_id     = "${::ec2id}.${::domain}"

        salt::grain { 'instanceproject':
            value => $::instanceproject,
        }
    } else {
        $master        = 'palladium.eqiad.wmnet'
        $master_finger = 'f6:1d:a7:1f:7e:12:10:40:75:d5:73:af:0c:be:7d:7c'
        $client_id     = $::fqdn
    }

    class { '::salt::minion':
        id            => $client_id,
        master        => $master,
        master_finger => $master_finger,
        grains         => {
            realm   => $::realm,
            site    => $::site,
            cluster => $cluster,
        },
    }
}
