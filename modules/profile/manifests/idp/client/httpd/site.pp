# @summary private define used to configure an apache vhost using mod_auth_cas
# @param vhost_content an erb template file to use for the apache vhost configuration
# @param server_aliases an array of additional server aliases
# @param document_root the document root to configure for the apache vhost
# @param cookie_path The location where cas stores information relating to authentication cookies issued
# @param certificate_path the SSL certificate path used for validation
# @param apereo_cas hash holding the login and validation
# @param authn_header The prefix to use when adding CAS or SAML attributes to the HTTP headers
# @param debug Enable cas debug
# @param priority the priority of the vhost site.  default: 99
# @param validate_saml if true set CASValidateSAML On
# @param enable_monitor if true an icinga check to make sure the site correctly redirects
# @param protected_uri The protected URI endpoint which is validated if "enable_monitor" is set.  default: '/'
# @param required_groups An array of LDAP groups allowed to access this resource
# @param acme_chief_cert the name of the acme chief certificate to use
# @param vhost_settings Allows to pass settings to the vhost config which are unrelated to the IDP setup
# @param proxied_as_https if true set the proxied_as address to https://${vhost}/
# @attribute_delimiter mod_auth_cas will set the value of the attribute header (as described in CASAttributePrefix)
#   to <attrvalue><CASAttributeDelimiter><attrvalue> in the case of multiple attribute values.
define profile::idp::client::httpd::site (
    String[1]                     $vhost_content,
    Stdlib::Host                  $virtual_host         = $title,
    Stdlib::Unixpath              $document_root       = '/var/www',
    Array[Stdlib::Host]           $server_aliases      = [],
    String[1]                     $authn_header        = 'CAS-User',
    String[1]                     $attribute_prefix    = 'X-CAS-',
    Boolean                       $debug               = false,
    Integer[1,99]                 $priority            = 50,
    Boolean                       $validate_saml       = false,
    Boolean                       $enable_monitor      = true,
    String[1]                     $protected_uri       = '/',
    String[1]                     $cookie_scope        = $protected_uri,
    Boolean                       $proxied_as_https    = false,
    String[1,1]                   $attribute_delimiter = ',',
    Enum['staging', 'production'] $environment         = 'production',
    Optional[Hash[String,Any]]    $vhost_settings      = {},
    Optional[Array[String[1]]]    $required_groups     = [],
    Optional[String[1]]           $acme_chief_cert     = undef,
) {
    include profile::idp::client::httpd
    $apereo_cas        = $profile::idp::client::httpd::apereo_cas
    $apache_owner      = $profile::idp::client::httpd::apache_owner
    $apache_group      = $profile::idp::client::httpd::apache_group
    $certificate_path  = $profile::idp::client::httpd::certificate_path
    $cookie_path       = "${profile::idp::client::httpd::cookie_path}/${title}/"
    $ssl_settings      = ssl_ciphersuite('apache', 'strong', true)
    $proxied_as = $proxied_as_https ? {
        true    => "https://${title}",
        default => undef,
    }
    $cas_settings = {
        'CASLoginURL'           => $apereo_cas[$environment]['login_url'],
        'CASValidateURL'        => $apereo_cas[$environment]['validate_url'],
        'CASDebug'              => $debug ? { true => 'On', default => 'Off' },
        'CASRootProxiedAs'      => $proxied_as,
        'CASVersion'            => 2,
        'CASCertificatePath'    => $certificate_path,
        'CASCookiePath'         => $cookie_path,
        'CASAttributePrefix'    => $attribute_prefix,
        'CASAttributeDelimiter' => $attribute_delimiter,
        'CASValidateSAML'       => $validate_saml ? { true => 'On', default => 'Off' },
    }

    $cas_auth_require = $required_groups.empty? {
        true    => ['valid-user' ],
        default => $required_groups.map |$group| { "cas-attribute memberOf:${group}" },
    }
    $cas_auth_settings = {
        'AuthType'       => 'CAS',
        'CASAuthNHeader' => $authn_header,
        'CASScope'       => $cookie_scope,
        'Require'        => $cas_auth_require,
    }
    file{$cookie_path:
        ensure => directory,
        owner  => $apache_owner,
        group  => $apache_group,
    }

    if $acme_chief_cert and !defined(Acme_chief::Cert[$acme_chief_cert]) {
        acme_chief::cert { $acme_chief_cert:
            puppet_svc => 'apache2',
        }
    }

    httpd::site {$title:
        content  => template($vhost_content),
        priority => $priority,
    }

    if $enable_monitor {
        monitoring::service {"https-${title}-unauthorized":
            description   => "${title} requires authentication",
            check_command => "check_https_sso_redirect!${title}!${protected_uri}",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/CAS-SSO/Administration',
        }
    }
}
