# @summary configure an apache web site using mod_auth_cas
# @param vhost_content an erb template file to use for the apache vhost configuration
# @param virtual_host the virtual host to use in the apache vhost
# @param document_root the document root to configure for the apache vhost
# @param cookie_path The location where cas stores information relating to authentication cookies issued
# @param certificate_path the SSL certificate path used for validation
# @param apereo_cas hash holding the login and validation
# @param authn_header The prefix to use when adding CAS or SAML attributes to the HTTP headers
# @param debug Enable cas debug
# @param apache_owner The user apache runs as
# @param apache_group The group apache runs as
# @param priority the priority of the vhost site.  default: 99
# @param validate_saml if true set CASValidateSAML On
# @param enable_monitor if true an icinga check to make sure the site correctly redirects
# @param protected_uri The protected URI endpoint which is validated if "enable_monitor" is set.  default: '/'
# @param required_groups An array of LDAP groups allowed to access this resource
# @param acme_cheif_cert the name of the acme chief certificate to use
# @param proxied_as This URL represents the URL that end users may see in the event that Apache server is proxied
class profile::idp::client::httpd (
    Hash[String, Stdlib::HTTPUrl] $apereo_cas       = lookup('apereo_cas', Hash, 'hash'),
    String[1]                     $vhost_content    = lookup('profile::idp::client::httpd::vhost_content'),
    Stdlib::Host                  $virtual_host     = lookup('profile::idp::client::httpd::virtual_host'),
    Stdlib::Unixpath              $document_root    = lookup('profile::idp::client::httpd::document_root'),
    Stdlib::Unixpath              $cookie_path      = lookup('profile::idp::client::httpd::cookie_path'),
    Stdlib::Unixpath              $certificate_path = lookup('profile::idp::client::httpd::certificate_path'),
    String[1]                     $authn_header     = lookup('profile::idp::client::httpd::authn_header'),
    String[1]                     $attribute_prefix = lookup('profile::idp::client::httpd::attribute_prefix'),
    Boolean                       $debug            = lookup('profile::idp::client::httpd::debug'),
    String[1]                     $apache_owner     = lookup('profile::idp::client::httpd::apache_owner'),
    String[1]                     $apache_group     = lookup('profile::idp::client::httpd::apache_group'),
    Integer[1,99]                 $priority         = lookup('profile::idp::client::httpd::priority'),
    Boolean                       $validate_saml    = lookup('profile::idp::client::httpd::validate_saml'),
    Boolean                       $enable_monitor   = lookup('profile::idp::client::httpd::enable_monitor'),
    String[1]                     $protected_uri    = lookup('profile::idp::client::httpd::protected_uri'),
    Optional[Array[String[1]]]    $required_groups  = lookup('profile::idp::client::httpd::required_groups'),
    Optional[String[1]]           $acme_chief_cert  = lookup('profile::idp::client::httpd::acme_chief_cert',
                                                            {'default_value' => undef}),
    Optional[String[1]]           $proxied_as       = lookup('profile::idp::client::httpd::proxied_as',
                                                            {'default_value' => undef}),
) {
    ensure_packages(['libapache2-mod-auth-cas'])

    $_cookie_path = $cookie_path[-1] ? {
        '/'     => $cookie_path,
        default => "${cookie_path}/",
    }
    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)
    $cas_settings = {
        'CASVersion'         => 2,
        'CASCertificatePath' => $certificate_path,
        'CASCookiePath'      => $_cookie_path,
        'CASLoginURL'        => $apereo_cas['login_url'],
        'CASValidateURL'     => $apereo_cas['validate_url'],
        'CASAttributePrefix' => $attribute_prefix,
        'CASDebug'           => $debug ? { true => 'On', default => 'Off' },
        'CASValidateSAML'    => $validate_saml ? { true => 'On', default => 'Off' },
        'CASRootProxiedAs'   => $proxied_as,
    }
    $cas_base_auth = {
        'AuthType'       => 'CAS',
        'CASAuthNHeader' => $authn_header,
    }
    $cas_auth_require = $required_groups.empty? {
        true    => ['valid-user' ],
        default => $required_groups.map |$group| { "cas-attribute memberOf:${group}" },
    }
    $cas_auth_settings = merge($cas_base_auth, {'Require' => $cas_auth_require})

    if $acme_chief_cert {
        acme_chief::cert { $acme_chief_cert:
            puppet_svc => 'apache2',
        }
    }

    httpd::mod_conf{'auth_cas':}
    file{$cookie_path:
        ensure => directory,
        owner  => $apache_owner,
        group  => $apache_group,
    }
    httpd::site {$virtual_host:
        content  => template($vhost_content),
        priority => $priority,
    }
    if $enable_monitor {
        monitoring::service {"https-${virtual_host}-unauthorized":
            description   => "${virtual_host} requires authentication",
            check_command => "check_sso_redirect!${virtual_host}!${protected_uri}",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/CAS-SSO/Administration',
        }
    }
}


