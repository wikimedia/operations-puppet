# == Class: beta::scap::target
#
# Provisions scap components for a scap target node.
#
class beta::scap::target {
    include ::beta::config
    include ::mediawiki::scap
    include ::mediawiki::users

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
}

