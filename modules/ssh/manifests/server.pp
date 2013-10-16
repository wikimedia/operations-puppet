class ssh::server {

    package { 'openssh-server':
    ensure => latest;
    }
}

# XXX: uses global variables ssh_x11_forwarding & ssh_tcp_forwarding
#
#should be converted into a parameterized class...
file { '/etc/ssh/sshd_config':
    owner   => root,
    group   => root,
    mode    => '0444',
    content => template('ssh/sshd_config.erb');
    }

    service { 'ssh':
    ensure    => running,
    subscribe => File['/etc/ssh/sshd_config'];
    }

    if ($::realm == 'labs') {
    file { '/etc/ssh/sshd_banner':
    owner   => root,
    group   => root,
    mode    => '0444',
    content => "\nIf you are having access problems, please see:https://labsconsole.wikimedia.org/wiki/Access#Accessing_public_and_private_instances\n",
    }

    if versioncmp($::lsbdistrelease, '12.04') >= 0 {
    $ssh_authorized_keys_file ='/etc/ssh/userkeys/%u/.ssh/authorized_keys /public/keys/%u/.ssh/authorized_keys'
    }
    else {
        $ssh_authorized_keys_file ='/etc/ssh/userkeys/%u/.ssh/authorized_keys'
        $ssh_authorized_keys_file2 = '/public/keys/%u/.ssh/authorized_keys'

    }
}

    # publish this hosts's host key
    case $::sshrsakey {
    '': {
        err("No sshrsakey on ${::fqdn}")
    }
    default: {
        debug("Storing RSA SSH hostkey for ${::fqdn}")
        @@ssh::hostkey { $::fqdn:
        ip  => $::ipaddress,
        key => $::sshrsakey,
        }
    }
}
