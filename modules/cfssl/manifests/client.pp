# @summary configure cfssl client
# @param ensure whether to ensure the resource
# @param conf_dir location of the configuration directory
# @param auth_key The sha256 hmac key
class cfssl::client (
    Stdlib::HTTPUrl  $signer,
    String           $auth_key,
    Wmflib::Ensure   $ensure    = 'present',
    Cfssl::Loglevel  $log_level = 'info',
) {
    $conf_file = '/etc/cfssl/client-cfssl.conf'
    ensure_packages(['golang-cfssl'])
    $default_auth_remote = {'remote' => 'default_remote', 'auth_key' => 'default_auth'}
    $auth_keys = {'default_auth'     => { 'type' => 'standard', 'key'  => $auth_key}}
    $remotes = {'default_remote' => $signer}
    cfssl::config {'client-cfssl':
        default_auth_remote => $default_auth_remote,
        auth_keys           => $auth_keys,
        remotes             => $remotes,
        require             => Package['golang-cfssl'],
    }
    file {'/usr/local/sbin/cfssl-client':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0550',
        content => "#!/bin/sh\n/usr/bin/cfssl \"$@\" -config ${conf_file}";
    }
}
