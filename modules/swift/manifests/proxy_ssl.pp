# Class swift::proxy_ssl
#
# Set up nginx to terminate SSL connections, using the local machine's puppet
# certificates.
class swift::proxy_ssl (
  $ensure = 'present',
  $client_max_body_size='2G',
) {
    validate_ensure($ensure)
    validate_re("${client_max_body_size}", "[0-9]+[MGmg]")

    ::base::expose_puppet_certs { '/etc/nginx':
        ensure          => $ensure,
        provide_private => true,
        require         => Class['nginx'],
    }

    $ssl_settings = ssl_ciphersuite('nginx', 'strong')
    include ::sslcert::dhparam
    ::nginx::site { 'swift-proxy':
        ensure  => $ensure,
        content => template('swift/nginx.conf.erb'),
        require => Class['::sslcert::dhparam']
    }

    diamond::collector::nginx{ 'swift-proxy':
        ensure => $ensure,
    }
}
