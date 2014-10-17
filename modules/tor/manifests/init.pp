# sets up a Tor relay
class tor (
    $tor_address,
    $tor_nickname,
    $tor_contact,
    $tor_controlport = '9051',
    $tor_orport = '443', # use 9001 if in use
    $tor_dirport = '80', # use 9030 if in use
    $tor_exit_policy = 'reject *:*',
    ) {

    # tor itself
    package { 'tor':
        ensure => 'present',
    }

    # status monitor for tor
    # https://www.atagar.com/arm/
    package { 'tor-arm':
        ensure => 'present',
    }

    # main config file
    file { '/etc/tor/torrc':
        ensure  => 'present',
        mode    => '0444',
        owner   => 'root',
        group   => 'root',
        content => template('tor/torrc.erb'),
        notify  => Service['tor'],
        require => Package['tor'],
    }

    service { 'tor':
        ensure  => 'running',
        require => Package['tor'],
    }

    # TC - Tor control protocol, private
    # https://gitweb.torproject.org/torspec.git?a=blob_plain;hb=HEAD;f=control-spec.txt
    ferm::service { 'tor_controlport':
        desc   => 'control port for the tor relay'
        proto  => 'tcp',  # can be TCP, TLS-over-TCP, or Unix-domain socket
        port   => '9051', # default
        srange => $::INTERNAL, # keep private for security!
    }

    # actual Tor port where clients connect, public
    ferm::service { 'tor_orport':
        desc   => 'port for the actual Tor client connections',
        proto  => 'tcp',
        port   => '443',
    }

    # for serving directory updates, public
    ferm::service { 'tor_dirport':
        desc   => 'port advertising the directory service'
        proto  => 'tcp',
        port   => '80',
    }
}
