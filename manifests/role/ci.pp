# vim: set et ts=4 sw=4:

# role::ci::master
#
# Setup a Jenkins installation attended to be used as a master. This setup some
# CI specific requirements such as having workspace on a SSD device and Jenkins
# monitoring.
class role::ci::master {
    system_role { 'role::ci::master': description => 'CI Jenkins master' }

    # We require the CI website to be on the same box as the master
    # as of July 2013.  So make sure the website has been included on the node.
    Class['role::ci::master'] -> Class['role::ci::website']

    # Load the Jenkins module, that setup a Jenkins master
    include ::jenkins,
      contint::proxy_jenkins

    # .gitconfig file required for rare git write operations
    git::userconfig { '.gitconfig for jenkins user':
      homedir => '/var/lib/jenkins',
      settings => {
        'user' => {
          'name'  => 'Wikimedia Jenkins Bot',
          'email' => 'jenkins@gallium.wikimedia.org',
        },  # end of [user] section
      },  # end of settings
      require => User['jenkins'],
    }

    file { '/srv/ssd/jenkins':
        ensure  => 'directory',
        owner   => 'jenkins',
        group   => 'jenkins',
        mode    => '2775',  # group sticky bit
        # Mount is handled on the node definition
        require => Mount['/srv/ssd'],
    }

    # Master does not run job anymore since June 2013. But better safe than
    # sorry.  We might have to run some jobs there.
    file { '/srv/ssd/jenkins/workspace':
        ensure  => 'directory',
        owner   => 'jenkins',
        group   => 'jenkins',
        mode    => '0775',
        require => [
            File['/srv/ssd/jenkins'],
        ],
    }

    contint::tmpfs { 'tmpfs for jenkins CI master':
        user        => 'jenkins',
        group       => 'jenkins',
        mount_point => '/var/lib/jenkins/tmpfs',
        size        => '512M',
    }

    # Ganglia monitoring for Jenkins
    # The upstream module is named 'jenkins' which conflicts with python-jenkins
    # since gmond will lookup the 'jenkins' python module in the system path
    # before the module path.
    # See: https://github.com/ganglia/monitor-core/issues/111

    file { '/usr/lib/ganglia/python_modules/jenkins.py':
        ensure => absent,
    }
    file { '/usr/lib/ganglia/python_modules/gmond_jenkins.py':
        source => 'puppet:///files/ganglia/plugins/jenkins.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Service['gmond'],
    }

    file { '/etc/ganglia/conf.d/jenkins.pyconf':
        ensure => absent,
    }
    file { '/etc/ganglia/conf.d/gmond_jenkins.pyconf':
        source => 'puppet:///files/ganglia/plugins/jenkins.pyconf',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        notify => Service['gmond'],
    }
}

# Set up a Jenkins slave suitable for Continuous Integration jobs execution.
# You will need to setup the Gerrit replication on the Gerrit server by
# amending the role::gerrit::production class
class role::ci::slave {
    system_role { 'role::ci::slave': description => 'CI slave runner' }

    include contint::packages,
        role::gerrit::production::replicationdest

    class { 'jenkins::slave':
        ssh_authorized_key => 'AAAAB3NzaC1yc2EAAAABIwAAAQEA4QGc1Zs/S4s7znEYw7RifTuZ4y4iYvXl5jp5tJA9kGUGzzfL0dc4ZEEhpu+4C/TixZJXqv0N6yke67cM8hfdXnLOVJc4n/Z02uYHQpRDeLAJUAlGlbGZNvzsOLw39dGF0u3YmwDm6rj85RSvGqz8ExbvrneCVJSaYlIRvOEKw0e0FYs8Yc7aqFRV60M6fGzWVaC3lQjSnEFMNGdSiLp3Vl/GB4GgvRJpbNENRrTS3Te9BPtPAGhJVPliTflVYvULCjYVtPEbvabkW+vZznlcVHAZJVTTgmqpDZEHqp4bzyO8rBNhMc7BjUVyNVNC5FCk+D2LagmIriYxjirXDNrWlw==',
        ssh_key_name       => 'jenkins@gallium',
        # Lamely restrict to master which is gallium
        ssh_key_options    => [ 'from="208.80.154.135"' ],
        user               => 'jenkins-slave',
        workdir            => '/srv/ssd/jenkins-slave',
        # Mount is handled on the node definition
        require            => Mount['/srv/ssd'],
    }

    # .gitconfig file required for rare git write operations
    git::userconfig { '.gitconfig for jenkins user':
      homedir => '/var/lib/jenkins-slave',
      settings => {
        'user' => {
          'name'  => 'Wikimedia Jenkins Bot',
          'email' => "jenkins-slave@${::fqdn}",
        },  # end of [user] section
      },  # end of settings
      require => User['jenkins-slave'],
    }

    contint::tmpfs { 'tmpfs for jenkins CI slave':
        user        => 'jenkins-slave',
        group       => 'jenkins-slave',
        mount_point => '/var/lib/jenkins-slave/tmpfs',
        size        => '128M',
    }

    # Setup Gerrit replication destination:
    file { '/srv/ssd/gerrit':
        ensure => 'directory',
        owner  => 'gerritslave',
        group  => 'root',
        mode   => '0755',
    }
}

# The testswarm installation
# Although not used as of July 2013, we will resurect this one day.
class role::ci::testswarm {
    system_role { 'role::ci::testswarm': description => 'CI Testswarm' }

    include contint::testswarm
}

# Website for Continuous integration
#
# http://doc.mediawiki.org/
# http://doc.wikimedia.org/
# http://integration.mediawiki.org/
# http://integration.wikimedia.org/
class role::ci::website {
  system_role { 'role::ci::website': description => 'CI Websites' }

  include role::zuul::configuration

  class { 'contint::website':
    zuul_git_dir => $role::zuul::configuration::zuul_git_dir,
  }
}
