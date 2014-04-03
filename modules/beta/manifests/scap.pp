# == Class: beta::scap
#
# Provisions scap components specfic to the beta environment.
#
class beta::scap {
    include beta::config

    # Install authorized_keys for mwdeploy user
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

    # Install ssh public key for mwdeploy user
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

    # Hack to replace /etc/security/access.conf (which is managed by the
    # ldap::client class) with a modified version that includes an access
    # grant for the mwdeploy user to authenticate from deployment-bastion.
    file { '/etc/security/access.conf~':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => template('beta/pam-access.conf.erb'),
    }

    File <| title == '/etc/security/access.conf' |> {
        content => undef,
        source  => '/etc/security/access.conf~',
        require => File['/etc/security/access.conf~'],
    }
}
