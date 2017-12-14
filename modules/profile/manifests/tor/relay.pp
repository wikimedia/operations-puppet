# sets up a tor relay
class profile::tor::relay {

    include passwords::tor
    $controlpassword = $passwords::tor::hashed_control_password

    # The default instance is special, listening on 80/443
    class { '::tor':
        nickname        => 'wikimediaeqiad1',
        controlport     => '9051',
        controlpassword => $controlpassword,
        orport          => '443',
        dirport         => '80',
        address         => 'tor-eqiad-1.wikimedia.org',
        contact         => 'noc@wikimedia.org',
        exit_policy     => 'reject *:*', # no exits allowed
    }

    # actual Tor port where clients connect, public
    ferm::service { 'tor_orport_wikimediaeqiad1':
        desc  => 'port for the actual Tor client connections',
        proto => 'tcp',
        port  => '443',
    }

    # for serving directory updates, public
    ferm::service { 'tor_dirport_wikimediaeqiad1':
        desc  => 'port advertising the directory service',
        proto => 'tcp',
        port  => '80',
    }

    # setup multiple additional instances, each with their own id and ports
    ['2', '3'].each |$instance| {
        $instance_name = "wikimediaeqiad${instance}"
        $controlport = "905${instance}"
        $orport = "900${instance}"
        $dirport = "903${instance}"

        ::tor::instance { $instance_name:
            nickname        => $instance_name,
            controlport     => $controlport,
            controlpassword => $controlpassword,
            orport          => $orport,
            dirport         => $dirport,
            address         => 'tor-eqiad-1.wikimedia.org',
            contact         => 'noc@wikimedia.org',
            exit_policy     => 'reject *:*', # no exits allowed
        }

        ferm::service { "tor_orport_${instance_name}":
            desc  => 'port for the actual Tor client connections',
            proto => 'tcp',
            port  => $orport,
        }
        ferm::service { "tor_dirport_${instance_name}":
            desc  => 'port advertising the directory service',
            proto => 'tcp',
            port  => $dirport,
        }
    }
}
