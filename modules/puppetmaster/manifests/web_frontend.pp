# == Define puppetmaster::web_frontend
#
# Allows to define a virtual host (and the corresponding ssl needs)
# for a puppetmaster frontend.
#
# === Parameters
#
# [*workers*]
#   A list of workers, as an array of hashes in the form:
#     [{ 'worker' => 'worker1.example.com', loadfactor => '1' }]
#   If loadfactor is omitted, it is assumed to be equal to 1
#
# [*master*]
#   The fqdn of the master frontend (e.g. puppetmaster1001.eqiad.wmnet)
#
# [*bind_address*]
#   IP address to bind to.
#
# [*priority*]
#   The priority of the apache vhost. Defaults to 90
#
# [*alt_names*]
#   Alternative names, if any, which should be accepted.
define puppetmaster::web_frontend(
    $workers,
    $master,
    $bind_address='*',
    $priority=90,
    $alt_names=undef,
){
    $server_name = $title
    $ssldir = $::puppetmaster::ssl::ssldir
    $ssl_settings = ssl_ciphersuite('apache', 'compat')

    if $server_name != $::fqdn {
        # The files called with secret() should be generated on the current
        # puppetmaster::ca_server with "puppet cert generate" and committed to
        # the private repository.
        # We use the private repo for the public key as well as it gets
        # generated on the puppet ca server.
        file { "${ssldir}/certs/${server_name}.pem":
            content => secret("puppetmaster/${server_name}_pubkey.pem"),
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            before  => Apache::Site[$server_name],
        }

        file { "${ssldir}/private_keys/${server_name}.pem":
            content => secret("puppetmaster/${server_name}_privkey.pem"),
            owner   => 'root',
            group   => 'root',
            mode    => '0640',
            before  => Apache::Site[$server_name],
        }
    }
    apache::site { $server_name:
        ensure   => present,
        content  => template('puppetmaster/web-frontend.conf.erb'),
        priority => $priority,
    }

}
