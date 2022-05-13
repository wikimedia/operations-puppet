# SPDX-License-Identifier: Apache-2.0
# @summary configure cfssl client
# @param ensure whether to ensure the resource
# @param conf_dir location of the configuration directory
# @param auth_key The sha256 hmac key
# @param enable_proxy if true configure cfssl api to listen on $listen_addr:$listen_port
class cfssl::client (
    Stdlib::HTTPUrl            $signer,
    Stdlib::Filesource         $bundles_source,
    Sensitive[String[1]]       $auth_key,
    Wmflib::Ensure             $ensure                 = 'present',
    Cfssl::Loglevel            $log_level              = 'info',
    Boolean                    $enable_proxy           = false,
    Stdlib::IP::Address        $listen_addr            = '127.0.0.1',
    Stdlib::Port               $listen_port            = 8888,
    Optional[Stdlib::Unixpath] $mutual_tls_client_cert = undef,
    Optional[Stdlib::Unixpath] $mutual_tls_client_key  = undef,
    Optional[Stdlib::Unixpath] $tls_remote_ca          = undef,
) {
    if $ensure == 'present' {
        include cfssl
    }
    $conf_file = "${cfssl::conf_dir}/client-cfssl.conf"
    $default_auth_remote = {'remote' => 'default_remote', 'auth_key' => 'default_auth'}
    # for now we need to unwrap the sensitive value otherwise it is not interpreted
    # Related bug: PUP-8969
    $auth_keys = {'default_auth'     => { 'type' => 'standard', 'key' => $auth_key.unwrap}}
    $remotes = {'default_remote' => $signer}
    cfssl::config {'client-cfssl':
        ensure              => $ensure,
        default_auth_remote => $default_auth_remote,
        auth_keys           => $auth_keys,
        remotes             => $remotes,
        path                => $conf_file,
    }
    file {'/usr/local/sbin/cfssl-client':
        ensure  => stdlib::ensure($ensure, 'file'),
        owner   => 'root',
        group   => 'root',
        mode    => '0550',
        content => "#!/bin/sh\n/usr/bin/cfssl \"$@\" -config ${conf_file}";
    }
    systemd::service {'cfssl-serve@proxy-client':
        ensure  => $enable_proxy.bool2str('present', 'absent'),
        content => template('cfssl/cfssl.service.erb'),
        restart => true,
    }
}
