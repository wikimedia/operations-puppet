class role::tor {

    system::role { 'tor':
        description => 'Tor relay'
    }

    include passwords::tor
    $controlpassword = $passwords::tor::hashed_control_password

    class { '::tor':
        tor_controlport     => '9051',
        tor_controlpassword => $controlpassword,
        tor_orport          => '443',
        tor_dirport         => '80',
        tor_address         => 'tor-eqiad-1.wikimedia.org',
        tor_nickname        => 'wikimediaeqiad1',
        tor_contact         => 'noc@wikimedia.org',
        tor_exit_policy     => 'reject *:*', # no exits allowed
    }

    # actual Tor port where clients connect, public
    ferm::service { 'tor_orport':
        desc  => 'port for the actual Tor client connections',
        proto => 'tcp',
        port  => '443',
    }

    # for serving directory updates, public
    ferm::service { 'tor_dirport':
        desc  => 'port advertising the directory service',
        proto => 'tcp',
        port  => '80',
    }
}
