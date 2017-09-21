# Set up a Jenkins slave on PRODUCTION
#
# Most jobs are running on labs instances, but we still have a few runnining
# directly on the Jenkins master for example to publish publish content under
# https://doc.wikimedia.org/
#
# You should look instaed at role::ci::labs::slave
#
class role::ci::slave {

    system::role { 'ci::slave': description => 'CI slave runner' }


    include contint::packages::base
    include contint::slave_scripts
    include ::profile::ci::docker
    include ::profile::zuul::cloner

    $username = hiera('jenkins_agent_username')

    class { 'jenkins::slave':
        # Master connect to itself via the fqdn / primary IP ipaddress
        ssh_key => "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA4QGc1Zs/S4s7znEYw7RifTuZ4y4iYvXl5jp5tJA9kGUGzzfL0dc4ZEEhpu+4C/TixZJXqv0N6yke67cM8hfdXnLOVJc4n/Z02uYHQpRDeLAJUAlGlbGZNvzsOLw39dGF0u3YmwDm6rj85RSvGqz8ExbvrneCVJSaYlIRvOEKw0e0FYs8Yc7aqFRV60M6fGzWVaC3lQjSnEFMNGdSiLp3Vl/GB4GgvRJpbNENRrTS3Te9BPtPAGhJVPliTflVYvULCjYVtPEbvabkW+vZznlcVHAZJVTTgmqpDZEHqp4bzyO8rBNhMc7BjUVyNVNC5FCk+D2LagmIriYxjirXDNrWlw== jenkins@gallium from=\"${::ipaddress}\"",
        user    => $username,
        workdir => "/srv/${username}",
    }

    # .gitconfig file required for rare git write operations
    git::userconfig { ".gitconfig for ${username} user":
        homedir  => "/var/lib/${username}",
        settings => {
            'user' => {
                'name'  => 'Wikimedia Jenkins Bot',
                'email' => "${username}@${::fqdn}",
            },  # end of [user] section
        },  # end of settings
        require  => User[$username],
    }
}
