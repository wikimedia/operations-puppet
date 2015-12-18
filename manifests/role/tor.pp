class role::tor {

    system::role { 'tor':
        description => 'Tor relay'
    }

    include passwords::tor
    $controlpassword = $passwords::tor::hashed_control_password

    class { '::tor':
        controlport     => '9051',
        controlpassword => $controlpassword,
        orport          => '443',
        dirport         => '80',
        address         => 'tor-eqiad-1.wikimedia.org',
        nickname        => 'wikimediaeqiad1',
        contact         => 'noc@wikimedia.org',
        exit_policy     => 'reject *:*', # no exits allowed
    }

    ::tor::instance { 'wikimediaeqiad2':
        controlport     => '9052',
        controlpassword => $controlpassword,
        orport          => '9002',
        dirport         => '9032',
        address         => 'tor-eqiad-2.wikimedia.org',
        nickname        => 'wikimediaeqiad2',
        contact         => 'noc@wikimedia.org',
        exit_policy     => 'reject *:*', # no exits allowed
    }

    # actual Tor port where clients connect, public
    ferm::service { 'tor_orport':
        desc  => 'port for the actual Tor client connections',
        proto => 'tcp',
        port  => '(443 9002)',
    }

    # for serving directory updates, public
    ferm::service { 'tor_dirport':
        desc  => 'port advertising the directory service',
        proto => 'tcp',
        port  => '(80 9032)',
    }
}
