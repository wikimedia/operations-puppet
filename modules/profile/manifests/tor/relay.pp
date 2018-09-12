# sets up a tor relay
class profile::tor::relay (
    $service_ensure = hiera('profile::tor::relay::service_ensure'),
    $fingerprints = hiera('profile::tor::relay::fingerprints'),
) {

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
        apt_uri         => 'http://apt.wikimedia.org/wikimedia',
        apt_dist        => "${::lsbdistcodename}-wikimedia",
        service_ensure  => $service_ensure,
        fingerprints    => $fingerprints,
    }

    ::tor::instance { 'wikimediaeqiad2':
        controlport     => '9052',
        controlpassword => $controlpassword,
        orport          => '9002',
        dirport         => '9032',
        address         => 'tor-eqiad-1.wikimedia.org',
        nickname        => 'wikimediaeqiad2',
        contact         => 'noc@wikimedia.org',
        fingerprints    => $fingerprints,
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

    monitoring::service { 'tor_orport':
        description   => 'Tor ORPort',
        check_command => 'check_tcp!9002',
    }

    monitoring::service { 'tor_dirport':
        description   => 'Tor DirPort',
        check_command => 'check_tcp!9032',
    }

    backup::set { 'tor': }
}
