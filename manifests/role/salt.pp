class role::salt::masters::production {

    $salt_state_roots    = { 'base'=>['/srv/salt']}
    $salt_file_roots     = { 'base'=>['/srv/salt']}
    $salt_pillar_roots   = { 'base'=>['/srv/pillars']}
    $salt_module_roots   = { 'base'=>['/srv/salt/_modules']}
    $salt_returner_roots = { 'base'=>['/srv/salt/_returners']}

    class { 'salt::master':
        salt_runner_dirs    => ['/srv/runners'],
        salt_peer_run       => {
            'tin.eqiad.wmnet'  => ['deploy.*'],
            'mira.codfw.wmnet' => ['deploy.*'],
        },
        salt_file_roots     => $salt_file_roots,
        salt_pillar_roots   => $salt_pillar_roots,
        salt_worker_threads => '30',
        salt_state_roots    => $salt_state_roots,
        salt_module_roots   => $salt_module_roots,
        salt_returner_roots => $salt_returner_roots,
    }

}

# A salt master that manages all labs minions
class role::salt::masters::labs {

    $puppet_master = hiera('labs_puppet_master')

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
        salt_state_roots    => $salt_state_roots,
        salt_module_roots   => $salt_module_roots,
        salt_returner_roots => $salt_returner_roots,
        salt_auto_accept    => true,
    }

    class { 'salt::reactors':
        salt_reactor_options => { 'puppet_server' => $puppet_master },
    }


    if ! defined(Class['puppetmaster::certmanager']) {
        include role::nova::config
        $novaconfig = $role::nova::config::novaconfig

        class { 'puppetmaster::certmanager':
            remote_cert_cleaner => $novaconfig['designate_hostname'],
        }
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
        salt_state_roots    => $salt_state_roots,
        salt_module_roots   => $salt_module_roots,
        salt_returner_roots => $salt_returner_roots,
        salt_auto_accept    => true,
    }

}

class role::salt::minions(
    $salt_master     = $::salt_master_override,
    $salt_finger     = $::salt_master_finger_override,
    $salt_master_key = $::salt_master_key,
) {
    if $::realm == 'labs' {
        $labs_master = hiera('labs_puppet_master')

        $labs_finger   = 'c5:b1:35:45:3e:0a:19:70:aa:5f:3a:cf:bf:a0:61:dd'
        $master        = pick($salt_master, $labs_master)
        $master_finger = pick($salt_finger, $labs_finger)

        salt::grain { 'labsproject':
            value => $::labsproject,
        }
    } else {
        $master = 'palladium.eqiad.wmnet'
        $master_finger = 'f6:1d:a7:1f:7e:12:10:40:75:d5:73:af:0c:be:7d:7c'
    }
    $client_id     = $::fqdn

    class { '::salt::minion':
        id            => $client_id,
        master        => $master,
        master_finger => $master_finger,
        master_key    => $salt_master_key,
        grains        => {
            realm   => $::realm,
            site    => $::site,
            cluster => hiera('cluster', $cluster),
        },
    }
}
