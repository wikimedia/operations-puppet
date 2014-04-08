# Class: shinken::receiver
#
# Install, configure and ensure running for shinken receiver daemon
class shinken::receiver {
    class { 'shinken::daemon':
        daemon      => 'receiver',
        conf_file   => '/etc/shinken/receiverd.ini'
    }
}
