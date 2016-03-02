# = Class: elasticsearch::https
#
# This class configures HTTPS for elasticsearch
#
# == Parameters:
# - ensure: self explanatory
class elasticsearch::https (
    $ensure = 'absent',
){

    ::base::expose_puppet_certs { '/etc/haproxy':
        ensure          => $ensure,
        provide_private => true,
        user            => 'haproxy',
        group           => 'haproxy',
        ssldir          => '/var/lib/puppet/client/ssl',
    }

    if $ensure == 'present' {
        exec { 'concat-haproxy-certificates':
            path        => '/bin:/usr/bin',
            command     => 'cat /etc/haproxy/ssl/certs/cert.pem /etc/haproxy/ssl/private_keys/server.key > /etc/haproxy/ssl/private_keys/cert_and_key.pem',
            refreshonly => true,
            subscribe   => [
                File['/etc/haproxy/ssl/certs/cert.pem'],
                File['/etc/haproxy/ssl/private_keys/server.key'],
            ],
            before => File['/etc/haproxy/ssl/private_keys/cert_and_key.pem'],
        }
    }

    file {'/etc/haproxy/ssl/private_keys/cert_and_key.pem':
        ensure => $ensure,
        owner  => 'haproxy',
        group  => 'haproxy',
        mode   => '0400',
    }

    class {'haproxy':
        ensure   => $ensure,
        template => 'elasticsearch/haproxy/haproxy.cfg.erb',
    }

}
