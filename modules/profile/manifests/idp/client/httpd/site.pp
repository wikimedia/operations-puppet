# SPDX-License-Identifier: Apache-2.0
# @summary private define used to configure an apache vhost using mod_auth_cas
# @param vhost_content an erb template file to use for the apache vhost configuration
# @param virtual_host FQDN of vhost
# @param server_aliases an array of additional server aliases
# @param document_root the document root to configure for the apache vhost
# @param cookie_scope The location where cas stores information relating to authentication cookies issued
# @param authn_header The prefix to use when adding CAS or SAML attributes to the HTTP headers
# @param attribute_prefix string to use as a prefix for header attribute mapping
# @param debug Enable cas debug
# @param priority the priority of the vhost site.  default: 99
# @param validate_saml if true set CASValidateSAML On
# @param enable_monitor if true an icinga check to make sure the site correctly redirects
# @param protected_uri The protected URI endpoint which is validated if "enable_monitor" is set.  default: '/'
# @param required_groups An array of LDAP groups allowed to access this resource
# @param vhost_settings Allows to pass settings to the vhost config which are unrelated to the IDP setup
# @param proxied_as_https if true set the proxied_as address to https://${vhost}/
# @param attribute_delimiter delimeter to use when mapping lists
# @param environment either production or staging environment
# @param enable_slo enable the Single Logout (SLO) endpoint, this is called by CAS when someone logs out of the sso session
# @attribute_delimiter mod_auth_cas will set the value of the attribute header (as described in CASAttributePrefix)
#   to <attrvalue><CASAttributeDelimiter><attrvalue> in the case of multiple attribute values.
# @param cookie_same_site Specify the value for the 'SameSite=' parameter in the Set-Cookie header.
#    Allowed values are 'None', 'Lax', and 'Strict'.
# @param cookie_secure Set the optional 'Secure' attribute for cookies issued by mod_auth_cas.
#    Set the Secure attribute as described in in RFC 6265. This flag prevents the mod_auth_cas
#    cookies from being sent over an unencrypted HTTP connection. By default, mod_auth_cas sets the
#    'Secure' attribute depending on information about the connection (the 'Auto' option).
#    The options 'On' and 'Off' can be used to override the automatic behaviour.
# @param acme_chief_cert the name of the acme chief certificate to use
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
    String[1,1]                   $attribute_delimiter = ':',
    Enum['staging', 'production'] $environment         = 'production',
    Boolean                       $enable_slo          = true,
    Wmflib::HTTP::SameSite        $cookie_same_site    = 'Lax',
    Enum['Auto', 'On', 'Off']     $cookie_secure       = 'On',
    Hash[String,Any]              $vhost_settings      = {},
    Array[String[1]]              $required_groups     = [],
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
    $validate_url_key = $validate_saml.bool2str('validate_url_saml', 'validate_url')
    $validate_url = $apereo_cas[$environment][$validate_url_key]
    $cas_settings = {
        'CASLoginURL'           => $apereo_cas[$environment]['login_url'],
        'CASValidateURL'        => $validate_url,
        'CASDebug'              => $debug.bool2str('On', 'Off'),
        'CASRootProxiedAs'      => $proxied_as,
        'CASVersion'            => 2,
        'CASCertificatePath'    => $certificate_path,
        'CASCookiePath'         => $cookie_path,
        'CASAttributePrefix'    => $attribute_prefix,
        'CASAttributeDelimiter' => $attribute_delimiter,
        'CASValidateSAML'       => $validate_saml.bool2str('On', 'Off'),
        'CASSSOEnabled'         => $enable_slo.bool2str('On', 'Off'),
        'CASCookieSameSite'     => $cookie_same_site,
        'CASCookieSecure'       => $cookie_secure,
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
        monitoring::service {"https-${title}-expiry":
            description   => "${title} tls expiry",
            check_command => "check_https_expiry!${title}!443",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/CAS-SSO/Administration',
        }
    }
}
