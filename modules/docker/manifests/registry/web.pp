# @summary configure the docker registry web site
# @param docker_username the docker username to use
# @param docker_password_hash the docker password hash to use
# @param allow_push_from A list of host allowed to push
# @param ssl_settings an aray of ssl_settings
# @param use_puppet_certs if true use puppet certs
# @param use_acme_chief_certs if true use acme certs
# @param http_endpoint if true configuer a plain text http endpoint
# @param http_allowed_hosts A loist of host allowed to use http
# @param cors configuer cors
# @param ssl_certificate_name The ssl certificate name to use
# @param index_redirect url to redirect curious people visiting the domain root to
class docker::registry::web (
    String                     $docker_username,
    String                     $docker_password_hash,
    Array[Stdlib::Host]        $allow_push_from,
    Array[String]              $ssl_settings,
    Boolean                    $use_puppet_certs     = false,
    Boolean                    $use_acme_chief_certs = false,
    Boolean                    $http_endpoint        = false,
    Array[Stdlib::Host]        $http_allowed_hosts   = [],
    Boolean                    $cors                 = false,
    Optional[String]           $ssl_certificate_name = undef,
    Optional[Stdlib::HTTPSUrl] $index_redirect       = undef,
) {
    if (!$use_puppet_certs and ($ssl_certificate_name == undef)) {
        fail('Either puppet certs should be used, or an ssl cert name should be provided')
    }

    if $use_puppet_certs {
        # TODO: consider using profile::pki::get_cert
        puppet::expose_agent_certs { '/etc/nginx':
            ensure          => present,
            provide_private => true,
            require         => Class['nginx'],
        }
    }

    file { '/etc/nginx/htpasswd.registry':
        content => "${docker_username}:${docker_password_hash}",
        owner   => 'www-data',
        group   => 'www-data',
        mode    => '0440',
        before  => Service['nginx'],
        require => Package['nginx-common'],
    }
    nginx::site { 'registry':
        content => template('docker/registry-nginx.conf.erb'),
    }

    if $http_endpoint {
        nginx::site { 'registry-http':
            content => template('docker/registry-http-nginx.conf.erb'),
        }
    }

}
