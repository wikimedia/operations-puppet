# = Class: mjolnir
#
# This class installs the MjoLniR (Machine Learned Ranking) data
# processing package.
#
class mjolnir {
    require_package('virtualenv', 'zip')

    file { '/etc/mjolnir':
        ensure => 'directory',
        owner  => 'deploy-service',
        group  => 'deploy-service',
        mode   => '0755',
    }

    scap::target { 'search/mjolnir/deploy':
        deploy_user => 'deploy-service',
    }
}


