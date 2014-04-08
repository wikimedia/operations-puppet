# Class: shinken::broker
#
# Install, configure and ensure running for shinken broker daemon 
class shinken::broker {
    class { 'shinken::daemon':
        daemon      => 'broker',
        conf_file   => '/etc/shinken/brokerd.ini'
    }
}
