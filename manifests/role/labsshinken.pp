# = Class: role::labs::shinken
# Sets up a shinken server for labs

class role::labs::shinken {
    class { 'shinken::server': }
}
