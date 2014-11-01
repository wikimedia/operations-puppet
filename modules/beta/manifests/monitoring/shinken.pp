# = Class: beta::monitoring::shinken
# Sets up shinken monitoring for betacluster
class beta::monitoring::shinken {
    shinken::hosts { 'betacluster-hosts':
        source => 'puppet:///modules/beta/shinken/hosts.cfg',
    }
}