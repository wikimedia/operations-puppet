# == Class puppetmaster::ca_server
#
# Configure a given puppetmaster to act as CA server.
#
# === Parameters
#
# [*master*]
#   The fqdn of the master frontend (e.g. puppetmaster1001.eqiad.wmnet)
#
# [*server_name*]
#   The server name used by Apache to serve the CA.
#
# [*cert_secret_path*]
#   Path to puppet keys/certs in secrets repository.

class puppetmaster::ca_server(
    $master,
    $server_name = 'puppet',
    $cert_secret_path = 'puppetmaster',
){
    $ssldir = '/var/lib/puppet/server/ssl'

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
