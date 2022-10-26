# This profile sets up an bastion/dev instance in the Toolforge model.
class profile::toolforge::bastion () {
    include profile::toolforge::shell_environ
    include profile::toolforge::k8s::client
    include profile::toolforge::jobs_framework_cli

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

    # General SSH Use Configuration
    file { '/etc/ssh/ssh_config':
        ensure => file,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/profile/toolforge/submithost-ssh_config',
    }

    apt::repository { 'thirdparty-tekton':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => 'thirdparty/tekton',
    }
}
