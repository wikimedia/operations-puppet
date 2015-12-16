# == Class scap::ferm
# Allows ssh access from $DEPLOYMENT_HOSTS
#
class scap::ferm {
    # allow ssh from deployment hosts
    ferm::rule { 'deployment-ssh':
        ensure => present,
        rule   => 'proto tcp dport ssh saddr $DEPLOYMENT_HOSTS ACCEPT;',
    }
}
