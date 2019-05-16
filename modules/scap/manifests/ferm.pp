# == Class scap::ferm
# Allows ssh access from $DEPLOYMENT_HOSTS
#
class scap::ferm {
    # allow ssh from deployment hosts
    ferm::service { 'deployment-ssh':
        ensure => present,
        proto  => 'tcp',
        port   => 'ssh',
        srange => '$DEPLOYMENT_HOSTS',
    }
}
