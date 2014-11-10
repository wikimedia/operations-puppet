# = Class: role::labs::shinken
# Sets up a shinken server for labs

class role::labs::shinken {
    class { 'shinken::server':
        auth_secret => 'This is insecure, should switch to using private repo',
    }

    # Basic labs monitoring
    shinken::services { 'basic-checks':
        source => 'file:///modules/shinken/basic-checks.cfg':
    }

    include beta::monitoring::shinken
}
