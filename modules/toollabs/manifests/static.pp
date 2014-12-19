# = Class: toollabs::proxy
#
# A static http server, serving static files from NFS
class toollabs::static(
    $resolver = '10.68.16.1',
    $ssl_certificate_name => 'star.wmflabs.org',
    $ssl_settings = ssl_ciphersuite('nginx', 'compat'),
) inherits toollabs {
    include toollabs::infrastructure

    if $ssl_certificate_name != false {
        install_certificate { $ssl_certificate_name:
            privatekey => false,
        }
    }

    nginx::site { 'static-proxy':
        source => 'puppet:///modules/toollabs/staticproxy.conf',
    }
}
