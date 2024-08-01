# SPDX-License-Identifier: Apache-2.0
# Set up a Jenkins agent on PRODUCTION
#
# Most jobs are running on labs instances, but we still have a few running
# directly on the Jenkins controller for example to publish publish content
# at https://doc.wikimedia.org/
#
# You should look instead at role::ci::labs::slave
#
#
class profile::ci::agent(
    String $user = lookup('jenkins_agent_username'),
    Array[String] $ssh_keys = lookup('profile::ci::agent::ssh_keys'),
) {

    include ::profile::java

    # the old RSA key is going to be replaced by a new ECDSA key - T177826

    class { 'jenkins::agent':
        # Master connect to itself via the fqdn / primary IP ipaddress
        ssh_key => join($ssh_keys, " from=\"${::ipaddress}\"\n"),
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
