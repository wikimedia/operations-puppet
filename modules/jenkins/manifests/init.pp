class jenkins {
    require jenkins::user
    require jenkins::group

    # Upgrades are usually done manually by upload the Jenkins
    # package at apt.wikimedia.org then restarting jenkins and
    # double checking everything went fine.
    package { 'jenkins':
        ensure => present,
    }

    # Graphiz is needed by the job dependency graph plugin
    package { 'graphviz':
        ensure => present,
    }

    # Jenkins should write everything group writable so admins can interact with
    # files easily, hence we need it to run with umask 0002.
    # The Jenkins software is daemonized in the init script using
    # /usr/bin/daemon which reset the umask value.  Daemon accepts per user
    # configuration via the ~/.daemonrc, set the umask there.
    file { '/var/lib/jenkins/.daemonrc':
        ensure  => 'present',
        content => "jenkins umask=0002\n",
        owner   => 'jenkins',
        group   => 'jenkins',
        mode    => '0644',
    }

    service { 'jenkins':
        ensure     => 'running',
        enable     => true,
        hasrestart => true,
        # Better have umask properly set before starting
        require    => File['/var/lib/jenkins/.daemonrc'],
    }

    # nagios monitoring
    nrpe::monitor_service { 'jenkins':
        description   => 'jenkins_service_running',
        contact_group => 'contint',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 --ereg-argument-array '^/usr/bin/java .*-jar /usr/share/jenkins/jenkins.war'"
    }

    file { '/var/lib/jenkins':
        ensure => directory,
        mode   => '2775',  # group sticky bit
        owner  => 'jenkins',
        group  => 'jenkins',
    }
    # Top level jobs folder
    file { '/var/lib/jenkins/jobs':
        ensure => directory,
        mode   => '2775',  # group sticky bit
        owner  => 'jenkins',
        group  => 'jenkins',
    }

    #FIXME: jenkins log rotation and init script
    # access.log rotation. Not provided by upstream Debian package
    # https://issues.jenkins-ci.org/browse/JENKINS-18870
    #  file { '/etc/logrotate.d/jenkins_accesslog':
    #  owner  => 'root',
    #  group  => 'root',
    #  mode   => '0444',
    #  source => 'puppet:///modules/jenkins/jenkins_accesslog.logrotate',
    #  }
    # Jenkins init script is broken and does not track the proper PID
    # additionally kill -s ALRM kills jenkins instead of making it reopen
    # its files.

    file { '/etc/logrotate.d/jenkins':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        source  => 'puppet:///modules/jenkins/jenkins_log.logrotate',
        require => Package['jenkins'],
    }

    file { '/etc/default/jenkins':
        ensure => present,
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        source => 'puppet:///modules/jenkins/etc_default_jenkins',
    }

}
