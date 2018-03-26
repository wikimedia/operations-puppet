# == Class puppetmaster::ca_server
#
# Configure a given puppetmaster to act as CA server.
#
# === Parameters
#
# [*master*]
#   The fqdn of the master frontend (e.g. puppetmaster1001.eqiad.wmnet)
#
# [*cert_secret_path*]
#   Path to puppet keys/certs in secrets repository.

class puppetmaster::ca_server(
    $master,
    $cert_secret_path = 'puppetmaster',
){
    $server_name = $title
    $ssldir = '/var/lib/puppet/ssl/server'

    if $master == $::fqdn {
        file { "${ssldir}/certs/${server_name}.pem":
            content   => secret("${cert_secret_path}/${server_name}_pubkey.pem"),
            owner     => 'puppet',
            group     => 'puppet',
            mode      => '0640',
            before    => Apache::Site[$server_name],
            show_diff => false,
        }

        file { "${ssldir}/private_keys/${server_name}.pem":
            content   => secret("${cert_secret_path}/${server_name}_privkey.pem"),
            owner     => 'puppet',
            group     => 'puppet',
            mode      => '0640',
            before    => Apache::Site[$server_name],
            show_diff => false,
        }
    }
}
