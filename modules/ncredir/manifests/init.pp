# == Class: ncredir
# this class handles common stuff for every non-canonical redirect service instance
# === Parameters
#
# [*ssl_settings*]
#   SSL/TLS settings are usually provided by ssl_ciphersuite().
#   Example:
#       ['ssl_protocols TLSv1 TLSv1.1 TLSv1.2;', 'ssl_dhparam /etc/ssl/dhparam.pem;', 'ssl_prefer_server_ciphers on;']
#   More information about nginx TLS settings available in https://nginx.org/en/docs/http/ngx_http_ssl_module.html
#
# [*redirection_maps*]
#   Redirection maps (http://nginx.org/en/docs/http/ngx_http_map_module.html)providing $rewrite and $override variables.
#   Usually provided by compile_redirects()
#
# [*acme_certificates*]
#   Hash containing the configuration used by acme-chief to issue the certificates intented to be used by the
#   non canonical redirect service.
#
# [*acme_chief_cert_prefix*]
#   Prefix used to match the certificates to be deployed from those specified in acme_certificates
#
# [*certs_basepath*]
#   Base path where acme_chief::cert deploys the certificates (default: /etc/acmecerts)
#
# [*http_port*]
#   Port used to serve HTTP requests (default: 80)
#
# [*https_port*]
#   Port used to serve HTTPS requests (default: 443)

class ncredir(
    Tuple[String, 1, default] $ssl_settings,
    String $redirection_maps,
    Hash[String, Hash[String, Any]] $acme_certificates,
    String $acme_chief_cert_prefix,
    Stdlib::AbsolutePath $certs_basepath = '/etc/acmecerts',
    Stdlib::Port $http_port = 80,
    Stdlib::Port $https_port = 443,
) {
    file {'/etc/nginx/conf.d/redirection_maps.conf':
        content => $redirection_maps,
        require => File['/etc/nginx/conf.d'],
        notify  => Service['nginx'],
    }

    nginx::site { 'ncredir':
        content => template('ncredir/ncredir.nginx.conf.erb'),
    }
}
