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

    file { '/etc/ssh/sshd_config':
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('ssh/sshd_config.erb'),
    }

    # publish this hosts's host key; prefer ECDSA -> RSA (no DSA)
    #
    # Puppet's sshkey provider tries to be smart and hardcodes key types that
    # it understands. While facter & puppet support came roughly at the same
    # time, here we only export the keys and the system that collects them may
    # have an older puppet version that doesn't understand a newer keytype.
    #
    # This is preventing us from exporting ed25519 keys from jessie hosts as
    # consuming them fails from precise & trusty hosts :(
    if $::sshecdsakey {
        $key  = $::sshecdsakey
        $type = 'ssh-ecdsa'
    } elsif $::sshrsakey {
        $key  = $::sshrsakey
        $type = 'ssh-rsa'
    } else {
        err("No valid SSH host key found for ${::fqdn}")
    }

    debug("Storing ${type} SSH hostkey for ${::fqdn}")
    @@sshkey { $::fqdn:
        ensure       => present,
        type         => $type,
        key          => $key,
        host_aliases => [ $::hostname, $::ipaddress ],
    }
}
