# == Class: keyholder
#
# The keyholder class provides a means of allowing a group of trusted
# users to use a shared SSH identity without exposing the identity's
# private key. This is accomplished by running a pair of SSH agents
# as system services: `keyholder-agent` and `keyholder-proxy`:
# `keyholder-agent` is the actual ssh-agent instance that holds the
# private key. `keyholder-proxy` proxies requests to the agent via a
# domain socket that is owned by the trusted user group. The proxy
# implements a subset of the ssh-agent protocol, allowing users to list
# identities and to use them to sign requests, but not to add or remove
# identities.
#
# The two services bind domain sockets at these addresses:
#
#   /run/keyholder
#   |__ agent.sock (0600)
#   |__ proxy.sock (0660)
#
# Before the shared SSH agent can be used, it must be armed by a user
# with access to the private key. This can be done by running:
#
#  $ SSH_AUTH_SOCK=/run/keyholder/agent.sock ssh-add /path/to/key
#
# Users in the trusted group can use the shared agent by running:
#
#  $ SSH_AUTH_SOCK=/run/keyholder/proxy.sock ssh remote-host ...
#

# === Bugs
#
# It is currently only possible to share an agent with a single group
#
class keyholder {
    require_package('python3')

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

    file { '/etc/keyholder.d':
        ensure  => directory,
        owner   => 'keyholder',
        group   => 'keyholder',
        mode    => '0750',
        recurse => true,
        purge   => true,
        force   => true,
    }

    file { '/usr/local/bin/ssh-agent-proxy':
        source => 'puppet:///modules/keyholder/ssh-agent-proxy',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',

        # Not possible for more than one keyholder per box
        # notify => Service['keyholder-agent'],
    }

    # The `keyholder` script provides a simplified command-line
    # interface for managing the agent. See `keyholder --help`.

    file { '/usr/local/sbin/keyholder':
        source => 'puppet:///modules/keyholder/keyholder',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',

        # Not possible for more than one keyholder per box
        # notify => Service['keyholder-proxy'],
    }
}
