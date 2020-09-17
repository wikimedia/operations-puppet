# @summary define an stunnle daemon
# @param ensure whether to ensure the resource
# @param accept_host The address to listen on
# @param accept_port The port to listen on
# @param connect_host The address to connect to
# @param connect_port The port to connect to
# @param client whether the daemon will also act as a client
# @param ca_path The path to the CA file
# @param cert_path the path to the client cert file
# @param key_path the path to the client private key file
# @param verify_peer if true verify the peer
# @param verify_client if true verify the client
# @param ssl_version The SSL version to use
# @param exec The binary to execute
# @param exec_args The arguments to execute
# @param debug Log level between 0 (emerg) and 7(debug)
define stunnel::daemon (
    Stdlib::Port               $accept_port,
    Wmflib::Ensure             $ensure       = 'present',
    Stdlib::Host               $accept_host  = 'localhost',
    Optional[Stdlib::Host]     $connect_host = undef,
    Optional[Stdlib::Port]     $connect_port = undef,
    Boolean                    $client       = false,
    Boolean                    $verify_chain = false,
    Boolean                    $verify_peer  = false,
    Integer[0,7]               $debug        = 5,
    Stunnel::Ssl_version       $ssl_version  = 'TLSv1.3',
    Optional[Stdlib::Unixpath] $exec         = undef,
    Array[String]              $exec_args    = [],
    Optional[Stdlib::Unixpath] $ca_path      = undef,
    Optional[Stdlib::Unixpath] $cert_path    = undef,
    Optional[Stdlib::Unixpath] $key_path     = undef,
) {
    include stunnel
    $safe_title = $title.regsubst('[^\w\-]', '_', 'G')
    $conf_file = "${stunnel::daemon_config_dir}/${safe_title}.conf"
    $connect_string = $connect_port ? {
        undef   => undef,
        default => $connect_host ? {
            undef   => $connect_port,
            default => "${connect_host}:${connect_port}",
        }
    }

    file {$conf_file:
        ensure  => $ensure,
        content => template('stunnel/daemon.conf.erb'),
        notify  => Service[$stunnel::service_name]
    }
}

