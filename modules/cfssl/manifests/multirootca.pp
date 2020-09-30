# @summary configure cfssl multirootca
# @param ensure whether to ensure this class
# @param signers a hash of signer configs
class cfssl::multirootca (
    Stdlib::Unixpath                $tls_cert,
    Stdlib::Unixpath                $tls_key,
    Wmflib::Ensure                  $ensure  = 'present',
    Stdlib::Host                    $host    = $facts['networking']['ip'],
    Stdlib::Port                    $port    = 8888,
    Hash[String, Cfssl::CA::Config] $signers = {},
) {
    include cfssl
    $config_file = "${cfssl::conf_dir}/multiroot.conf"
    file {$config_file:
        ensure  => $ensure,
        content => template('cfssl/multiroot.conf.erb'),
    }
    systemd::service {'cfssl-multirootca':
        content => template('cfssl/cfssl-multirootca.service.erb'),
        restart => true,
    }
}
