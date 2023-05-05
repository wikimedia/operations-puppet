# SPDX-License-Identifier: Apache-2.0
type Gitlab::Omniauth_provider::Cas3 = Struct[{
    'url'                            => Stdlib::Httpurl,
    Optional['login_url']            => Stdlib::Unixpath,
    Optional['logout_url']           => Stdlib::Unixpath,
    Optional['service_validate_url'] => Stdlib::Unixpath,
    Optional['uid_key']              => String[1],
    Optional['uid_field']            => String[1],
    Optional['email_field']          => String[1],
    Optional['name_field']           => String[1],
    Optional['nickname_field']       => String[1],
}]

