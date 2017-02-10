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
        if os_version("debian >= stretch") {
            # stretch's salt-minion uses SHA256 instead of MD5 by default.
            # while it's possible to set 'hash_type: md5', this is preferrable
            $master_finger = 'f6:36:06:73:ca:54:55:c4:68:17:66:13:47:4b:cf:3e:32:71:7a:70:2d:69:b4:e8:3b:f0:d0:ae:d0:4b:4c:f5'
        } else {
            $master_finger = 'f6:1d:a7:1f:7e:12:10:40:75:d5:73:af:0c:be:7d:7c'
        }
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
            cluster => hiera('cluster', $::cluster),
        },
    }
}
