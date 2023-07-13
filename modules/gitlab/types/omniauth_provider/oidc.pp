# SPDX-License-Identifier: Apache-2.0
type Gitlab::Omniauth_provider::OIDC = Struct[{
    'issuer'                                 => Stdlib::Httpurl,
    'client_options'                         => Struct[{
        'identifier'        => String[1],
        'redirect_uri'      => Stdlib::Httpurl,
        'userinfo_endpoint' => String,
        # The secret is optional to allow useres to first add the definition in puppet
        # and then to the private repo
        Optional['secret'] => String[1],
    }],
    Optional['scope']                        => Array[String[1],1],
    Optional['response_type']                => Enum['code', 'id_token'],
    Optional['discovery']                    => Boolean,
    Optional['client_auth_method']           => Enum['query', 'basic', 'jwt_bearer', 'mlts'],
    Optional['uid_field']                    => String[1],
    Optional['send_scope_to_token_endpoint'] => Boolean,
    Optional['pkce']                         => Boolean,
}]

