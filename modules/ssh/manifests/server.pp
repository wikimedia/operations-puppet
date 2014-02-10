class ssh::server {
    package { 'openssh-server':
        ensure => latest;
    }

    service { 'ssh':
        ensure    => running,
        subscribe => File['/etc/ssh/sshd_config'],
        provider  => 'upstart',
    }

    if ($::realm == 'labs') {
        if versioncmp($::lsbdistrelease, '12.04') >= 0 {
            $ssh_authorized_keys_file ='/etc/ssh/userkeys/%u/.ssh/authorized_keys /public/keys/%u/.ssh/authorized_keys'
        } else {
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

    file { '/etc/ssh/sshd_config':
        owner   => root,
        group   => root,
        mode    => '0444',
        content => template('ssh/sshd_config.erb');
    }
}
