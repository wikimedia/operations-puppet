# @summary configure cfssl client
# @param ensure whether to ensure the resource
# @param conf_dir location of the configuration directory
# @param auth_key The sha256 hmac key
class cfssl::client (
    Stdlib::HTTPUrl  $signer,
    String           $auth_key,
    Wmflib::Ensure   $ensure    = 'present',
    Cfssl::Loglevel  $log_level = 'info',
    Stdlib::Unixpath $conf_dir  = '/etc/cfssl',
) {
    ensure_packages(['golang-cfssl'])
    $conf_file = "${conf_dir}/client-cfssl.conf"
    $config = {
        'auth_keys' => {
            'default' => {
                'type' => 'standard',
                'key'  => $auth_key,
            },
        },
        'signing'   => {
            'default' => {
                'auth_remote' => {
                    'remote'   => 'default',
                    'auth_key' => 'default',
                }
            }
        },
        'remotes'   => {
            'default' => $signer,
        }
    }
    file {
        default:
            ensure  => $ensure,
            owner   => 'root',
            group   => 'root',
            mode    => '0440',
            require => Package['golang-cfssl'];
        $conf_file:
            content => $config.to_json();
        '/usr/local/sbin/cfssl-client':
            mode    => '0550',
            content => "#!/bin/sh\n/usr/bin/cfssl \"$@\" -config ${conf_file}";
    }
}
