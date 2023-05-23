# SPDX-License-Identifier: Apache-2.0
# Set up a Jenkins agent on PRODUCTION
#
# Most jobs are running on labs instances, but we still have a few running
# directly on the Jenkins controller for example to publish publish content
# at https://doc.wikimedia.org/
#
# You should look instead at role::ci::labs::slave
#

class profile::ci::agent(
    String $user = lookup('jenkins_agent_username'),
) {

    include ::profile::java

    class { 'jenkins::agent':
        # Master connect to itself via the fqdn / primary IP ipaddress
        ssh_key => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA4QGc1Zs/S4s7znEYw7RifTuZ4y4iYvXl5jp5tJA9kGUGzzfL0dc4ZEEhpu+4C/TixZJXqv0N6yke67cM8hfdXnLOVJc4n/Z02uYHQpRDeLAJUAlGlbGZNvzsOLw39dGF0u3YmwDm6rj85RSvGqz8ExbvrneCVJSaYlIRvOEKw0e0FYs8Yc7aqFRV60M6fGzWVaC3lQjSnEFMNGdSiLp3Vl/GB4GgvRJpbNENRrTS3Te9BPtPAGhJVPliTflVYvULCjYVtPEbvabkW+vZznlcVHAZJVTTgmqpDZEHqp4bzyO8rBNhMc7BjUVyNVNC5FCk+D2LagmIriYxjirXDNrWlw== jenkins@gallium from=\"${::ipaddress}\"",
        user    => $user,
        workdir => "/srv/${user}",
    }

    file { '/srv/deployment':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
    }

    # .gitconfig file required for rare git write operations
    git::userconfig { ".gitconfig for ${user} user":
        homedir  => "/var/lib/${user}",
        settings => {
            'user' => {
                'name'  => 'Wikimedia Jenkins Bot',
                'email' => "${user}@${$facts['networking']['fqdn']}",
            },  # end of [user] section
        },  # end of settings
        require  => User[$user],
    }
}
