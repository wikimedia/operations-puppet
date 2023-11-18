# This profile sets up an bastion/dev instance in the Toolforge model.
class profile::toolforge::bastion () {
    if debian::codename::eq('buster') {
        include profile::toolforge::shell_environ
    } else {
        ensure_packages([
            'emacs-nox',
            'neovim',
        ])
    }

    include profile::toolforge::k8s::client

    file { '/bin/disabledtoolshell':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/profile/toolforge/disabledtoolshell',
    }

    # misctools is in the tools aptly repo
    ensure_packages(['misctools'], {
        ensure => latest,
    })

    motd::script { 'bastion-banner':
        ensure => present,
        source => "puppet:///modules/profile/toolforge/40-${::wmcs_project}-bastion-banner.sh",
    }

    package { 'mosh':
        ensure => present,
    }

    apt::repository { 'thirdparty-tekton':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => 'thirdparty/tekton',
    }
}
