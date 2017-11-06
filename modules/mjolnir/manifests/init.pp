# = Class: mjolnir
#
# This class installs the MjoLniR (Machine Learned Ranking) data
# processing package.
#
class mjolnir {
    require_package('virtualenv', 'zip')

    scap::target { 'search/mjolnir/deploy':
        deploy_user => 'deploy-service',
    }
}


