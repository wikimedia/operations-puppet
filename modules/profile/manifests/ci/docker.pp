# == Class profile::ci::docker
#
# Configures a host to be a docker-backed Jenkins agent
#
class profile::ci::docker(
    $settings = lookup('profile::ci::docker::settings'),
) {
    # Having blubber on all docker nodes will give us a broad pool for all
    # jobs that require similar image building workloads
    require_package('blubber')

    apt::repository { 'thirdparty-ci':
        uri        => 'http://apt.wikimedia.org/wikimedia',
        dist       => "${::lsbdistcodename}-wikimedia",
        components => 'thirdparty/ci',
    }

    class { '::docker::configuration':
        settings => $settings,
    }
    $docker_version = $::lsbdistcodename ? {
        'jessie'  => '18.06.2~ce~3-0~debian',
        'stretch' => '18.06.2~ce~3-0~debian',
        'buster'  => '18.06.2~ce~3-0~debian',
    }
    class { '::docker':
        package_name => 'docker-ce',
        version      => $docker_version,
        require      => [
            Apt::Repository['thirdparty-ci'],
            Exec['apt-get update']
        ],
    }
    # Ship the entire docker iptables configuration via ferm
    # This is here to make sure docker and ferm play nice together.
    ferm::conf { 'docker-ferm':
        ensure => present,
        prio   => 20,
        source => 'puppet:///modules/profile/ci/docker-ferm',
    }
}
