# == Class: beta::scap
#
# Provisions scap components specfic to the beta environment
#
class beta::scap {
    include beta::config

    file { '/etc/ssh/userkeys/mwdeploy':
        ensure  => directory,
        owner   => 'mwdeploy',
        group   => 'mwdeploy',
        mode    => '0700',
        require => File['/etc/ssh/userkeys'],
    }
    file { '/etc/ssh/userkeys/mwdeploy/.ssh':
        ensure  => directory,
        owner   => 'mwdeploy',
        group   => 'mwdeploy',
        mode    => '0700',
        require => File['/etc/ssh/userkeys/mwdeploy'],
    }
    file { '/etc/ssh/userkeys/mwdeploy/.ssh/authorized_keys':
        owner   => 'mwdeploy',
        group   => 'mwdeploy',
        mode    => '0600',
        source  => 'puppet:///private/scap/id_rsa.pub',
        require => File['/etc/ssh/userkeys/mwdeploy/.ssh'],
    }

    file { '/etc/security/access.conf':
        owner    => 'root',
        group    => 'root',
        mode     => '0444',
        contents => template('beta/pam-access.conf.erb'),
    }

    if ($::instancename == 'deployment-bastion') {
        file { '/var/lib/mwdeploy/.ssh':
            ensure => directory,
            owner  => 'mwdeploy',
            group  => 'mwdeploy',
            mode   => '0700',
        }
        file { '/var/lib/mwdeploy/.ssh/id_rsa':
            owner   => 'mwdeploy',
            group   => 'mwdeploy',
            mode    => '0600',
            source  => 'puppet:///private/scap/id_rsa',
            require => File['/var/lib/mwdeploy/.ssh'],
        }
    }
}
