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

    if $alt_names {
        $alt_names_list = join(sort($alt_names), ',')
        $alt_names_cmd = " --dns_alt_names=${alt_names_list}"
    } else {
        $alt_names_cmd = ''
    }

    if $server_name != $::fqdn {
        # This is unfortunate, but "puppet cert generate"
        # just works locally, even if ca=false and a different ca server is
        # setup.
        # We will make it work writing a proper puppet resource once we are
        # settled on a PKI infrastructure to use, or we surrender to using the
        # puppet one forever.
        if $master != $::fqdn {
            fail('Alternative names are not supported for secundary puppetmasters.')
        }
        # Have puppet generate the certificate for this virtualhost
        # BEWARE: SSL key length cannot be controlled here
        exec { "generate hostcert for ${title}":
            require => File["${ssldir}/certs"],
            command => "/usr/bin/puppet cert generate ${server_name}${alt_names_cmd}",
            creates => "${ssldir}/certs/${server_name}.pem";
        }

    }
    apache::site { $server_name:
        ensure   => present,
        content  => template('puppetmaster/web-frontend.conf.erb'),
        priority => 90,
        require  => Exec["generate hostcert for ${title}"],
    }

}
