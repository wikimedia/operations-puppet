# @summary create a cfssl json config file
# @param auth_keys
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
    # make sure all profiles use the default auth key
    # first map to an array of [key, values] then convert to a hash
    $_profiles = Hash($profiles.map |$key, $value| {
        [$key, {'auth_key' => $default_auth_key} + $value]
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


