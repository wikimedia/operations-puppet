# = Class: elasticsearch::https
#
# This class configures HTTPS for elasticsearch
#
# == Parameters:
# - ensure: self explanatory
class elasticsearch::https (
    $ensure = 'absent',
){

    sslcert::certificate {'elasticsearch':
        ensure => $ensure,
    }

    class {'haproxy':
        ensure   => $ensure,
        template => 'elasticsearch/haproxy/haproxy.cfg',
    }

}
