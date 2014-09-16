# = Class: shinken::server
# Sets up a shinken monitoring server

class shinken::server {
    package { 'shinken':
        ensure  => present,
    }
}
