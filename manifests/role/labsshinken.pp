# = Class: role::labs::shinken
# Sets up a shinken server for labs

class role::labs::shinken {
    class { '::shinken':
        auth_secret => 'This is insecure, should switch to using private repo',
    }

    # Basic labs instance & infrastructure monitoring
    shinken::services { 'basic-infra-checks':
        source => 'puppet:///modules/shinken/labs/basic-infra-checks.cfg',
    }
    shinken::services { 'basic-instance-checks':
        source => 'puppet:///modules/shinken/labs/basic-instance-checks.cfg',
    }

    include beta::monitoring::shinken
}
