# Class nginx::simple_tlsproxy
#
# An nginx class to set up a reverse proxy with TLS termination for a local
# service.
#
# This is useful whenever the underlying service either has no TLS capabilities
# or it has bad TLS performance/features.
#
class nginx::simple_tlsproxy( $backend_port, $site_name, $port=443,) {
    validate_string($site_name)
    include ::nginx
    include ::nginx::ssl

    # T209709
    nginx::status_site { $site_name:
        port => 10080,
    }

    ::base::expose_puppet_certs { '/etc/nginx':
        ensure          => present,
        provide_private => true,
        require         => Class['nginx'],
    }

    ::nginx::site { "${site_name}_tls_termination":
        ensure  => present,
        content => template('nginx/simple_tlsproxy.erb')
    }
}
