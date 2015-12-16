# = class: scap::target
#
# Sets up a scap target, i.e. any host to which scap will deploy
# Currently, this only sets up ferm rules that will allow
# $DEPLOYMENT_HOSTS to ssh to this host.
#
# TODO: Make this class include ::scap when it is
# safe to do so.  That way targets don't have to
# remember to include the scap package separately
# from scap::target.
#
class scap::target {
    # allow ssh from deployment hosts
    ferm::rule { 'deployment-ssh':
        ensure => present,
        rule   => 'proto tcp dport ssh saddr $DEPLOYMENT_HOSTS ACCEPT;',
    }
}
