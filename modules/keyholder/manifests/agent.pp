# == keyholder::agent
#
# Resource for creating keyholder agents on a node
#
# === Parameters
#
# [*name*]
#   Used for service names, socket names, and default key name
#
# [*key_file*]
#   The name of the key file stored in puppet private
#   Should exist prior to running a defined resource
#
# [*trusted_group*]
#   The name or GID of the trusted user group with which the agent
#   should be shared. It is the caller's responsibility to ensure
#   the group exists.
#
# === Examples
#
#  keyholder::agent { 'mwdeploy':
#      trusted_group => 'wikidev',
#      require       => Group['wikidev'],
#  }
#
define keyholder::agent(
    $trusted_group,
    $key_file = "${name}_rsa",
) {

    $agent_socket = "/run/keyholder/agent-${name}.sock"
    $proxy_socket = "/run/keyholder/proxy-${name}.sock"

    # The `keyholder-agent` service is responsible for running
    # the ssh-agent instance that will hold shared key(s).

    file { "/etc/init/keyholder-${name}-agent.conf":
        content => template('keyholder/keyholder-agent.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service["keyholder-${name}-agent"],
    }

    service { "keyholder-${name}-agent":
        ensure   => running,
        provider => 'upstart',
        require  => File['/run/keyholder'],
    }


    # The `keyholder-proxy` service runs the filtering ssh-agent proxy
    # that acts as an intermediary between users in the trusted group
    # and the backend ssh-agent that holds the shared key(s).

    file { "/etc/init/keyholder-${name}-proxy.conf":
        content => template('keyholder/keyholder-proxy.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        notify  => Service["keyholder-${name}-proxy"],
    }

    service { "keyholder-${name}-proxy":
        ensure   => running,
        provider => 'upstart',
        require  => Service["keyholder-${name}-agent"],
    }

    # lint:ignore:puppet_url_without_modules
    keyholder::private_key { $key_file:
        source  => "puppet:///private/ssh/tin/${key_file}",
    }
    # lint:endignore
}
