class ssh::server (
    $listen_port = '22',
    $listen_address = undef,
    $permit_root = true,
) {
    package { 'openssh-server':
        ensure => latest;
    }

    service { 'ssh':
        ensure    => running,
        subscribe => File['/etc/ssh/sshd_config'],
    }

    if ($::realm == 'labs') {
        $ssh_authorized_keys_file ='/etc/ssh/userkeys/%u/.ssh/authorized_keys /public/keys/%u/.ssh/authorized_keys'
    }

    # publish this hosts's host key; prefer ed25519 -> ECDSA -> RSA (no DSA)
    if $::sshed25519key {
        debug("Storing ed25519 SSH hostkey for ${::fqdn}")
        @@ssh::hostkey { $::fqdn:
            ip   => $::ipaddress,
            key  => $::sshed25519key,
            type => 'ssh-ed25519',
        }
    } elsif $::sshecdsakey {
        debug("Storing ECDSA SSH hostkey for ${::fqdn}")
        @@ssh::hostkey { $::fqdn:
            ip   => $::ipaddress,
            key  => $::sshecdsakey,
            type => 'ssh-ecdsa',
        }
    } elsif $::sshrsakey {
        debug("Storing RSA SSH hostkey for ${::fqdn}")
        @@ssh::hostkey { $::fqdn:
            ip   => $::ipaddress,
            key  => $::sshrsakey,
            type => 'ssh-rsa',
        }
    } else {
        err("No SSH host key found for ${::fqdn}")
    }

    file { '/etc/ssh/sshd_config':
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('ssh/sshd_config.erb');
    }
}
