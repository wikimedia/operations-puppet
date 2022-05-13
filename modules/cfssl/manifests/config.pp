# SPDX-License-Identifier: Apache-2.0
# @summary create a cfssl json config file
# @param ensure ensurable parameter
# @param default_auth_key the default key to use if none specified
# @param default_usages the default usages to use if none specified
# @param default_auth_remote the default auth_remote to use if none specified
# @param auth_keys Hash of auth keys to configure
# @param profiles Hash of profiles to configure
# @param remotes Hash of remotes to configure
# @param default_expiry The default expiry to use if none provided in profile
# @param default_crl_url The default crl_url to use if none provided in profile
# @param default_ocsp_url The default ocsp_url to use if none provided in profile
# @param path the path to store the config file
define cfssl::config (
    Wmflib::Ensure                $ensure              = 'present',
    String                        $default_auth_key    = 'default_auth',
    Array[Cfssl::Usage]           $default_usages      = [],
    Hash[String, String]          $default_auth_remote = {},
    Hash[String, Cfssl::Auth_key] $auth_keys           = {},
    Hash[String, Cfssl::Profile]  $profiles            = {},
    Hash[String, Stdlib::HTTPUrl] $remotes             = {},
    Optional[Cfssl::Expiry]       $default_expiry      = undef,
    Optional[Stdlib::HTTPUrl]     $default_crl_url     = undef,
    Optional[Stdlib::HTTPUrl]     $default_ocsp_url    = undef,
    Optional[Stdlib::Unixpath]    $path                = undef,
) {
    if !$profiles.empty and $default_expiry == undef {
        fail('must provide a value for default_expiry if providing profiles')
    }
    if !$profiles.empty and $default_usages.empty {
        fail('must provide a value for default_usages if providing profiles')
    }
    unless $auth_keys.has_key($default_auth_key) {
        fail("auth_keys must have an entry for '${default_auth_key}'")
    }
    if $ensure == 'present' {
        include cfssl
    }
    $safe_title = $title.regsubst('\W', '_', 'G')
    $_path = $path ? {
        undef   => "${cfssl::conf_dir}/${safe_title}.conf",
        default => $path,
    }
    $default = {
        'auth_key'    => $default_auth_key,
        'usages'      => $default_usages,
        'expiry'      => $default_expiry,
        'crl_url'     => $default_crl_url,
        'ocsp_url'    => $default_ocsp_url,
        'auth_remote' => $default_auth_remote,
    }.filter |$key, $value| { $value =~ Boolean or !$value.empty() }
    # inject the default auth key if profiles dont specify one
    # first map to an array of [key, values] then convert to a hash
    $_profiles = Hash($profiles.map |$key, $value| {
        $_auth_key = pick($value['auth_key'], $default_auth_key)
        $_expiry = pick($value['expiry'], $default_expiry)
        $_usages = pick($value['usages'], $default_usages)
        # Make sure the specific auth key is defined
        unless $auth_keys.has_key($_auth_key) {
            fail("${key} 'auth_key: ${_auth_key}', not found in auth_keys (${auth_keys.keys.join(',')})")
        }
        [$key, {
            'auth_key' => $_auth_key,
            'expiry'   => $_expiry,
            'usages'   => $_usages,
        } + $value]  # we still add value incase it has ca_constraint
    })
    $signing = {
        'default'  => $default,
        'profiles' => $_profiles,
    }.filter |$key, $value| { $value =~ Boolean or !$value.empty() }
    $config = {
        'auth_keys' => $auth_keys,
        'signing'   => $signing,
        'remotes'   => $remotes,
    }.filter |$key, $value| { $value =~ Boolean or !$value.empty() }
    file{$_path:
        ensure    => $ensure,
        owner     => root,
        group     => root,
        mode      => '0440',
        show_diff => false,
        content   => Sensitive($config.to_json()),
    }
}
