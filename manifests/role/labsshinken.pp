# = Class: role::labs::shinken
# Sets up a shinken server for labs

class role::labs::shinken {
    class { 'shinken::server':
        auth_secret => 'This is insecure, should switch to using private repo',
    }

    include beta::monitoring::shinken
}
