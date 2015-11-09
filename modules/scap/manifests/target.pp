# = class: scap::master
#
# Sets up a scap target, i.e. any host to which scap will deploy

class scap::target {
    # allow ssh from deployment hosts
    ferm::rule { 'deployment-ssh':
        ensure => present,
        rule   => 'proto tcp dport ssh saddr $DEPLOYMENT_HOSTS ACCEPT;',
    }
}
