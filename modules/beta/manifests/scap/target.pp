# == Class: beta::scap::target
#
# Provisions scap components for a scap target node.
#
class beta::scap::target {
    include ::beta::config
    include ::mediawiki::sync
    include ::beta::mwdeploy_sudo

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

    # Target directory for scap
    file { $::beta::config::scap_deploy_dir:
        ensure  => directory,
        owner   => 'mwdeploy',
        group   => 'mwdeploy',
        mode    => '0755',
    }
}

