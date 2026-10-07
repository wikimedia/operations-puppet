# SPDX-License-Identifier: Apache-2.0
# @summary define a apereo_cas services
# @param id the numerical id
# @param service_id the id of the services i.e. the url pattern
# @param service_class The services class to use
# @param release_policy the release policy to use
# @param access_strategy the access strategy to use
# @param profile_format set the OIDC/OAuth2 profile view data format
# @param response_type the OAuth 2.0 response type that an OidcRegisteredService permits
# @param grant_types the OAuth 2.0 grant types that an OidcRegisteredService permits
# @param required_groups a list of required ldap groups for the services
# @param properties a list of addtional properties for the services
# @param allowed_delegate add an allowed delegated authentication provider
# @param client_secret the client_secret used for OIDC
# @param mfa enable multi factor authentication, specify relevant types
# @param mfa_optin allow users to opt-in/opt-out of MFA for this service using LDAP properties.
# @param client_roles if not empty, CAS accepts requests for this service only from the IPv4 and
#   IPv6 addresses of the hosts that have these roles, for example 'statistics::explorer'.
#   PuppetDB supplies the addresses.
define apereo_cas::service (
    Integer                              $id,
    String                               $service_id,
    Apereo_cas::Service::Class           $service_class      = 'CasRegisteredService',
    Apereo_cas::Service::Release_policy  $release_policy     = 'ReturnAllAttributeReleasePolicy',
    Apereo_cas::Service::Access_strategy $access_strategy    = 'DefaultRegisteredServiceAccessStrategy',
    ENUM['FLAT', 'NESTED']               $profile_format     = 'FLAT',
    String                               $response_type      = 'code',
    Apereo_cas::Service::Grant_types     $grant_types        = ['authorization_code'],
    Array[String]                        $required_groups    = [],
    Array[String]                        $mfa                = [],
    Hash                                 $properties         = {},
    Optional[String[1]]                  $allowed_delegate   = undef,
    Optional[String[1]]                  $client_secret      = undef,
    Optional[String[1]]                  $member_of_exclude  = undef,
    Boolean                              $mfa_optin          = false,
    Array[Wmflib::Role]                  $client_roles       = [],
) {
    if $service_class == 'OidcRegisteredService' {
        if !$client_secret {
            fail("${title}: \$client_secret required when using OidcRegisteredService")
        }

        $additional_params = {
            'clientId'               => $title,
            'clientSecret'           => $client_secret,
            'userProfileViewType'    => $profile_format,
            'bypassApprovalPrompt'   => true,
            'supportedResponseTypes' => [ 'java.util.HashSet', [ $response_type ] ],
            'supportedGrantTypes'    => [ 'java.util.HashSet', $grant_types ],
            'scopes'                 => [ 'java.util.HashSet', [ 'profile', 'openid', 'email', 'groups', 'memberOf'] ],
        }
    } else {
        $additional_params = {}
    }

    include apereo_cas
    $delegate = $allowed_delegate ? {
        undef   => {},
        default => {
            'delegatedAuthenticationPolicy' => {
                '@class'           => 'org.apereo.cas.services.DefaultRegisteredServiceDelegatedAuthenticationPolicy',
                'allowedProviders' => [ 'java.util.ArrayList', [ $allowed_delegate ]],
            },
        }
    }
    $ldap_root = "${apereo_cas::ldap_group_cn},${apereo_cas::ldap_base_dn}"
    if $required_groups.empty() {
        $base_access_strategy = { '@class' => "org.apereo.cas.services.${access_strategy}" }
    } else {
        $ldap_groups = $required_groups.map |$group| { "cn=${group},${ldap_root}" }
        $base_access_strategy = {
            '@class'             => "org.apereo.cas.services.${access_strategy}",
            'requiredAttributes' => {
                '@class'   => 'java.util.HashMap',
                'memberOf' => [
                    'java.util.HashSet',
                    $ldap_groups,
                ],
            },
        }
    }

    if $client_roles.empty() {
        $_access_strategy = $base_access_strategy + $delegate
    } else {
        $client_ips = $client_roles.map |$role| { wmflib::role::ips($role) }.flatten.unique.sort
        if $client_ips.empty() {
            warning("${title}: no host has the roles ${client_roles.join(', ')}, so CAS refuses all requests for this service")
        }
        # CAS must satisfy both strategies. CAS finds the address pattern anywhere in the
        # client address, so the pattern is anchored at both ends. If there are no addresses,
        # the pattern matches no address.
        $client_ip_pattern = $client_ips.map |$ip| { $ip.regsubst('\.', '[.]', 'G') }.join('|')
        $_access_strategy = {
            '@class'     => 'org.apereo.cas.services.ChainingRegisteredServiceAccessStrategy',
            'operator'   => 'AND',
            'strategies' => [
                'java.util.ArrayList',
                [
                    $base_access_strategy + $delegate,
                    {
                        '@class'    => 'org.apereo.cas.services.HttpRequestRegisteredServiceAccessStrategy',
                        'ipAddress' => "^(${client_ip_pattern})\$",
                    },
                ],
            ],
        }
    }

    if $mfa != [] and $mfa_optin {
        $multifactor_policy = {
            'multifactorPolicy' => {
                '@class'                             => 'org.apereo.cas.services.DefaultRegisteredServiceMultifactorPolicy',
                'multifactorAuthenticationProviders' => [ 'java.util.LinkedHashSet', [ join($mfa,',') ]],
                'bypassEnabled'                      => false,
                'forExecution'                       => true,
                'principalAttributeNameTrigger'      => 'mfa-method',
                'principalAttributeValueToMatch'     => 'mfa-gauth|mfa-webauthn'
            }
        }
    }
    elsif $mfa != [] {
        $multifactor_policy = {
            'multifactorPolicy' => {
                '@class'                             => 'org.apereo.cas.services.DefaultRegisteredServiceMultifactorPolicy',
                'multifactorAuthenticationProviders' => [ 'java.util.LinkedHashSet', [ join($mfa,',') ]],
                'bypassEnabled'                      => false,
                'forExecution'                       => true,
            }
        }
    } else {
        $multifactor_policy = {}
    }

    if $member_of_exclude {
        $attribute_release_policy = {
            '@class'            => "org.apereo.cas.services.${release_policy}",
            'attributeFilter'   => {
                '@class' => 'org.apereo.cas.services.support.RegisteredServiceReverseMappedRegexAttributeFilter',
                'patterns'                  => {
                    '@class'   => 'java.util.TreeMap',
                    'memberOf' => $member_of_exclude
                },
                'excludeUnmappedAttributes' => false,
                'completeMatch'             => false,
                'caseInsensitive'           => true,
                'order'                     => 0
            },
            'allowedAttributes' => [ 'java.util.HashSet', [ 'cn', 'sn', 'mail', 'memberOf', 'uid' ]]
        }
    } else {
        $attribute_release_policy = { '@class' => "org.apereo.cas.services.${release_policy}" }
    }

    $base_data = {
        '@class'                 => "org.apereo.cas.services.${service_class}",
        'name'                   => $title,
        'serviceId'              => $service_id,
        'attributeReleasePolicy' => $attribute_release_policy,
        'id'                     => $id,
        'accessStrategy'         => $_access_strategy,
    } + $additional_params + $multifactor_policy

    $data = $properties.empty ? {
        true    => $base_data,
        default => $base_data + { 'properties' => $properties },
    }
    file { "${apereo_cas::services_dir}/${title}-${id}.json":
        ensure  => file,
        content => $data.stdlib::to_json(),
    }
}
