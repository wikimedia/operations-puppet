# = Class: beta::monitoring::shinken
# Sets up shinken monitoring for betacluster
class beta::monitoring::shinken {
    shinken::config { 'betacluster-hosts':
        source => 'puppet:///modules/beta/shinken.cfg',
    }
}
