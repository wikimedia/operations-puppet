# == Class: keyholder
#
# The keyholder class provides a means of allowing a group of trusted
# users to use a shared SSH identity without exposing the identity's
# private key. This is accomplished by running a pair of SSH agents
# as system services: `keyholder-agent` and `keyholder-proxy`:
# `keyholder-agent` is the actual ssh-agent instance that holds the
# private key. `keyholder-proxy` proxies requests to the agent via a
# domain socket that is world readable. The proxy implements a subset
# of the ssh-agent protocol, allowing users to list identities and to
# use them to sign requests, but not to add or remove identities.
#
# The two services bind domain sockets at these addresses:
#
#   /run/keyholder
#   |__ agent.sock (0600)
#   |__ proxy.sock (0666)
#
# Before the shared SSH agent can be used, it must be armed by a user
# with access to the private key. This can be done by running:
#
#  $ /usr/local/sbin/keyholder arm
#
# Users in the trusted group can use the shared agent by running:
#
#  $ SSH_AUTH_SOCK=/run/keyholder/proxy.sock ssh remote-host ...
#
class keyholder($require_encrypted_keys='yes') {

    require_package('python3-yaml')

    group { 'keyholder':
        ensure => present,
    }

    user { 'keyholder':
        ensure     => present,
        gid        => 'keyholder',
        shell      => '/bin/false',
        home       => '/nonexistent',
        system     => true,
        managehome => false,
    }

    file { '/run/keyholder':
        ensure => directory,
        owner  => 'keyholder',
        group  => 'keyholder',
        mode   => '0755',
    }

    systemd::tmpfile { 'keyholder':
        content => 'd /run/keyholder 0755 keyholder keyholder',
        require => User['keyholder'],
    }

    file { '/etc/keyholder.d':
        ensure  => directory,
        owner   => 'keyholder',
        group   => 'keyholder',
        mode    => '0751',
        recurse => true,
        purge   => true,
        force   => true,
    }

    file { '/etc/keyholder-auth.d':
        ensure  => directory,
        owner   => 'keyholder',
        group   => 'keyholder',
        mode    => '0755',
        recurse => true,
        purge   => true,
        force   => true,
    }

    file { '/usr/local/bin/ssh-agent-proxy':
        source => 'puppet:///modules/keyholder/ssh-agent-proxy.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        notify => Service['keyholder-agent'],
    }

    # The `keyholder-agent` service is responsible for running
    # the ssh-agent instance that will hold shared key(s).
    systemd::service { 'keyholder-agent':
        ensure  => present,
        content => systemd_template('keyholder-agent'),
        restart => true,
        require => File['/run/keyholder'],
    }

    # The `keyholder-proxy` service runs the filtering ssh-agent proxy
    # that acts as an intermediary between users in the trusted group
    # and the backend ssh-agent that holds the shared key(s).
    systemd::service { 'keyholder-proxy':
        ensure  => present,
        content => systemd_template('keyholder-proxy'),
        restart => true,
        require => Service['keyholder-agent'],
    }

    file { '/etc/keyholder-auth.d/keyholder.conf':
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => "REQUIRE_ENCRYPTED_KEYS='${require_encrypted_keys}'\n",
    }

    # The `keyholder` script provides a simplified command-line
    # interface for managing the agent. See `keyholder --help`.
    file { '/usr/local/sbin/keyholder':
        source => 'puppet:///modules/keyholder/keyholder',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        notify => Service['keyholder-proxy'],
    }
}
