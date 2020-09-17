# @summary create a cfssl json config file
# @param auth_keys
define cfssl::config (
    Wmflib::Ensure                $ensure              = 'present',
    String                        $default_auth_key    = 'default_auth',
    Cfssl::Expiry                 $default_expiry      = '720h',
    Array[Cfssl::Usage]           $default_usages      = ['signing', 'key encipherment', 'client auth'],
    Hash[String, String]          $default_auth_remote = {},
    Optional[Stdlib::HTTPUrl]     $default_crl_url     = undef,
    Optional[Stdlib::HTTPUrl]     $default_ocsp_url    = undef,
    Hash[String, Cfssl::Auth_key] $auth_keys           = {},
    Hash[String, Cfssl::Profile]  $profiles            = {},
    Hash[String, Stdlib::HTTPUrl] $remotes             = {},
) {
    include cfssl
    $safe_title = $title.regsubst('[^\w-]', '_', 'G')
    $default = {
        'auth_key'    => $default_auth_key,
        'usages'      => $default_usages,
        'expiry'      => $default_expiry,
        'crl_url'     => $default_crl_url,
        'ocsp_url'    => $default_ocsp_url,
        'auth_remote' => $default_auth_remote,
    }.filter |$key, $value| { $value =~ Boolean or !$value.empty() }
    $signing = {
        'default'  => $default,
        'profiles' => $profiles,
    }.filter |$key, $value| { $value =~ Boolean or !$value.empty() }
    $config = {
        'auth_keys' => $auth_keys,
        'signing'   => $signing,
        'remotes'   => $remotes,
    }.filter |$key, $value| { $value =~ Boolean or !$value.empty() }
    file{"${cfssl::conf_dir}/${safe_title}.conf":
        ensure  => $ensure,
        owner   => root,
        group   => root,
        mode    => '0440',
        content => $config.to_json(),
    }
}


