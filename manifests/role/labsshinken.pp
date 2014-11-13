# = Class: role::labs::shinken
# Sets up a shinken server for labs
#
# = Parameters
#
# [*ircbot*]
#   Setup an ircbot using ircecho to support echoing notifications
#
class role::labs::shinken(
    $ircbot = true,
){
    class { 'shinken::server':
        auth_secret => 'This is insecure, should switch to using private repo',
    }

    # Basic labs monitoring
    shinken::services { 'basic-checks':
        source => 'puppet:///modules/shinken/basic-checks.cfg',
    }

    if $ircbot {
        include shinken::ircbot
    }

    include beta::monitoring::shinken
}
