# Sets up shinken alerts for toollabs

class toollabs::monitoring::shinken {

    shinken::config { 'toollabs':
        source => 'puppet:///modules/toollabs/shinken.cfg',
    }
}
