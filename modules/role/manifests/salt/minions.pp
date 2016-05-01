class role::salt::minions(
    $salt_master     = $::salt_master_override,
    $salt_finger     = $::salt_master_finger_override,
    $salt_master_key = $::salt_master_key,
) {
    if $::realm == 'labs' {
        $labs_master = hiera('saltmaster')

        $labs_finger   = 'c5:b1:35:45:3e:0a:19:70:aa:5f:3a:cf:bf:a0:61:dd'
        $master        = pick($salt_master, $labs_master)
        $master_finger = pick($salt_finger, $labs_finger)

        salt::grain { 'labsproject':
            value => $::labsproject,
        }
    } else {
        $master = 'neodymium.eqiad.wmnet'
        $master_finger = 'f6:1d:a7:1f:7e:12:10:40:75:d5:73:af:0c:be:7d:7c'
    }
    $client_id     = $::fqdn

    $default_grains = {
        realm   => $::realm,
        site    => $::site,
        cluster => hiera('cluster', $::cluster),
    }

    $hiera_grains = hiera('salt::additional_grains', {})
    $additional_grains = {}
    if ($::salt_additional_grains and size($::salt_additional_grains) > 0) {
        $additional_grains = $::salt_additional_grains
    }
    $grains = merge($default_grains, $hiera_grains, $additional_grains)

    class { '::salt::minion':
        id            => $client_id,
        master        => $master,
        master_finger => $master_finger,
        master_key    => $salt_master_key,
        grains        => $grains,
    }
}
