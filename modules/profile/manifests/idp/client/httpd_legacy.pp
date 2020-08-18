############################################################
############################################################
############# THIS CLASS WILL IS DEPRECATED ################
############################################################
############################################################
# @summary configure an apache web site using mod_auth_cas
# @param vhost_content an erb template file to use for the apache vhost configuration
# @param virtual_host the virtual host to use in the apache vhost
# @param server_aliases an array of additional server aliases
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
# @param acme_chief_cert the name of the acme chief certificate to use
# @param vhost_settings Allows to pass settings to the vhost config which are unrelated to the IDP setup
# @param proxied_as_https if true set the proxied_as address to https://${vhost}/
# @param staging if true also configure the staging  vhost as staging-${vhost}
class profile::idp::client::httpd_legacy (
    Apereo_cas::Urls              $apereo_cas       = lookup('apereo_cas', Apereo_cas::Urls, 'deep'),
    String[1]                     $vhost_content    = lookup('profile::idp::client::httpd::vhost_content'),
    Stdlib::Host                  $virtual_host     = lookup('profile::idp::client::httpd::virtual_host'),
    Array[Stdlib::Host]           $server_aliases   = lookup('profile::idp::client::httpd::server_aliases'),
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
    String[1]                     $cookie_scope     = lookup('profile::idp::client::httpd::cookie_scope'),
    Boolean                       $proxied_as_https = lookup('profile::idp::client::httpd::proxied_as_https'),
    Boolean                       $staging          = lookup('profile::idp::client::httpd::staging'),
    Optional[Hash[String,Any]]    $vhost_settings   = lookup('profile::idp::client::httpd::vhost_settings'),
    Optional[Array[String[1]]]    $required_groups  = lookup('profile::idp::client::httpd::required_groups'),
    Optional[String[1]]           $acme_chief_cert  = lookup('profile::idp::client::httpd::acme_chief_cert',
                                                            {'default_value' => undef}),
) {
    ensure_packages(['libapache2-mod-auth-cas'])

    $_cookie_path = $cookie_path[-1] ? {
        '/'     => $cookie_path,
        default => "${cookie_path}/",
    }
    $vhosts = $staging ? {
        true => [$virtual_host, "staging-${virtual_host}"],
        default => [$virtual_host],
    }
    $ssl_settings = ssl_ciphersuite('apache', 'strong', true)
    $cas_base_settings = {
        'CASVersion'         => 2,
        'CASCertificatePath' => $certificate_path,
        'CASCookiePath'      => $_cookie_path,
        'CASAttributePrefix' => $attribute_prefix,
        'CASValidateSAML'    => $validate_saml ? { true => 'On', default => 'Off' },
    }

    $cas_base_auth = {
        'AuthType'       => 'CAS',
        'CASAuthNHeader' => $authn_header,
        'CASScope'       => $cookie_scope,
    }
    $cas_auth_require = $required_groups.empty? {
        true    => ['valid-user' ],
        default => $required_groups.map |$group| { "cas-attribute memberOf:${group}" },
    }
    $cas_auth_settings = merge($cas_base_auth, {'Require' => $cas_auth_require})

    if $acme_chief_cert and !defined(Acme_chief::Cert[$acme_chief_cert]) {
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
    $vhosts.each |String $vhost| {
        if $vhost =~ '^/staging' {
            # always enable debug on staging
            $_debug = 'On'
            $login_url = $apereo_cas['staging']['login_url']
            $validate_url = $apereo_cas['staging']['validate_url']
        } else {
            $_debug = $debug ? { true => 'On', default => 'Off' }
            $login_url = $apereo_cas['production']['login_url']
            $validate_url = $apereo_cas['production']['validate_url']

        }
        $proxied_as = $proxied_as_https ? {
            true    => "https://${vhost}",
            default => undef,
        }
        $cas_settings = merge({
            'CASLoginURL'        => $login_url,
            'CASValidateURL'     => $validate_url,
            'CASDebug'           => $_debug,
            'CASRootProxiedAs'   => $proxied_as,
        }, $cas_base_settings)
        httpd::site {$vhost:
            content  => template($vhost_content),
            priority => $priority,
        }
    }

    if $enable_monitor {
        monitoring::service {"https-${virtual_host}-unauthorized":
            description   => "${virtual_host} requires authentication",
            check_command => "check_https_sso_redirect!${virtual_host}!${protected_uri}",
            notes_url     => 'https://wikitech.wikimedia.org/wiki/CAS-SSO/Administration',
        }
    }
}


