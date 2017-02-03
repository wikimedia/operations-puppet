# = Class: role::labs::shinken
# Sets up a shinken server for labs
#
# = Parameters
#
# [*ircbot*]
#   Setup an ircbot using ircecho to support echoing notifications
#
# filtertags: labs-project-shinken
class role::labs::shinken(
    $ircbot = true,
){
    class { '::shinken':
        auth_secret => 'This is insecure, should switch to using private repo',
    }

    # Basic labs instance & infrastructure monitoring
    shinken::config { 'basic-infra-checks':
        source => 'puppet:///modules/shinken/labs/basic-infra-checks.cfg',
    }
    shinken::config { 'basic-instance-checks':
        source => 'puppet:///modules/shinken/labs/basic-instance-checks.cfg',
    }

    if $ircbot {
        include shinken::ircbot
    }

    include beta::monitoring::shinken
    include toollabs::monitoring::shinken
}
