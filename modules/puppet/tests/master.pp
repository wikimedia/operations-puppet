#

# TODO: At some point this should not be needed
import '../../../manifests/nagios.pp'

class { 'puppet::self::master':
    server => 'localhost',
}
