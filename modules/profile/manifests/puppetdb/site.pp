# SPDX-License-Identifier: Apache-2.0
# @summary define to configure secondary proxies to the local puppetdb.  This allows
#  puppetserveres with different CA infrastructure to submit to the same puppetdb.
#  In order to use this you will need to generate additional private keys and certs
#  for the puppetdb servers.  This can be done from the puppetca server using the following
#  command
#   puppetserver ca generate $fqdn
#  The command should output the location of the certificates paths. You should copy these
#  to the necessary location in puppet and the private repo.
# @param port the port to listen
# @param cert_source the puppet source location to the cert file to use.
# @param key_secret_path a path to be passed to the secret function to get the content of the private key
# @param key_source if specified, will be used to 'source' the key instead of key_secret_path
# @param ca_source The puppet source location of the ca cert ot use for client auth.
#   You can get this by running the following on the puppet ca server
#   `cat $(sudo facter -p puppet_config.hostpubkey.localcacert)`
# @param jetty_port the port of the backend jetty server
# @param allowed_hosts a list of hosts allowed to use this site
define profile::puppetdb::site (
    Stdlib::Port                 $port,
    Stdlib::Filesource           $cert_source,
    Optional[String[1]]          $key_secret_path = undef,
    Optional[Stdlib::Filesource] $key_source = undef,
    Stdlib::Filesource           $ca_source,
    Stdlib::Port                 $jetty_port    = 8080,
    Array[Stdlib::Host]          $allowed_hosts = [],
) {
    include sslcert::dhparam  # lint:ignore:wmf_styleguide

    $ssl_dir = "/etc/nginx/ssl/${title}"
    wmflib::dir::mkdir_p($ssl_dir)
    $params = {
        'site_name'    => $title,
        'port'         => $port,
        'jetty_port'   => $jetty_port,
        'cert'         => "${ssl_dir}/cert.pem",
        'key'          => "${ssl_dir}/key.pem",
        'ca'           => "${ssl_dir}/ca.pem",
        'ssl_settings' => ssl_ciphersuite('nginx', 'mid'),
    }

    if $key_secret_path != undef and $key_source != undef {
        fail('Specify either $key_secret_path or $key_source, not both')
    }

    if $key_secret_path == undef and $key_source == undef {
        fail('One of $key_secret_path or $key_source must be defined')
    }

    if $key_secret_path != undef {
        file { $params['key']:
            ensure    => file,
            owner     => 'puppetdb',
            group     => 'puppetdb',
            show_diff => false,
            mode      => '0550',
            content   => secret($key_secret_path),
        }
    } else {
        file { $params['key']:
            ensure    => file,
            owner     => 'puppetdb',
            group     => 'puppetdb',
            show_diff => false,
            mode      => '0550',
            source    => $key_source,
        }
    }

    file {
        default:
            ensure    => file,
            owner     => 'puppetdb',
            group     => 'puppetdb',
            show_diff => false,
            mode      => '0550';
        $params['cert']:
            source => $cert_source;
        $params['ca']:
            source => $ca_source;
    }

    nginx::site { $title:
        ensure  => present,
        content => epp('profile/puppetdb/secondary.epp', $params),
    }
    unless $allowed_hosts.empty() {
        ferm::service { "puppetdb_${title}":
            proto  => tcp,
            port   => $port,
            srange => $allowed_hosts,
        }
    }
}
