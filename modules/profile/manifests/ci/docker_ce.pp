class profile::ci::docker_ce(
    $jenkins_user = hiera('profile::ci::docker_ce::jenkins_user')
) {
    apt::repository { 'thirdparty-ci':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => 'thirdparty/ci',
    }
    package { 'docker-ce':
        ensure  => present,
        require => [
          Apt::Repository['thirdparty-ci'],
          Exec['apt-get update']
        ],
    }

    # Ensure jenkins-deploy membership in the docker group
    exec { "${jenkins_user} docker membership":
        unless  => "/usr/bin/id -Gn ${jenkins_user} | /bin/grep -qw 'docker'",
        command => "/usr/sbin/usermod -aG docker ${jenkins_user}",
        require => [
            Package['docker-ce'],
        ],
    }
}
