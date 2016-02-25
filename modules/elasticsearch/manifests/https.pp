# = Class: elasticsearch::https
#
# This class configures HTTPS for elasticsearch
#
# == Parameters:
# - ensure: self explanatory
class elasticsearch::https (
    $ensure = 'absent',
){

    ::sslcert::expose_puppet_certs { '/etc/haproxy':
        ensure          => $ensure,
        provide_private => true,
        user            => 'haproxy',
        group           => 'haproxy',
    }

    class {'haproxy':
        ensure   => $ensure,
        template => 'elasticsearch/haproxy/haproxy.cfg.erb',
    }

}
