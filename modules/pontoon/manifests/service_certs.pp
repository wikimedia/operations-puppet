# SPDX-License-Identifier: Apache-2.0
# Generate service certificates via Puppet CA and cergen
#
# The class takes a CA server (the puppet server itself in Pontoon) and
# (possibly a subset of) service::catalog to issue CA-signed service certs.

# The resulting keypairs are named after the service::catalog key with their
# SANs set to the service's pontoon::service_names() function.

# For each service name symbolic links are installed under 'ssl/' in
# private.git, therefore existing calls to sslcert::certificate will work
# unmodified.

# Limitations and tradeoffs:
# * Old/removed keypairs and symlinks are not removed
# * To remove or renew a certificate delete its private key and 'puppet cert clean' it
# * To add a service alias you need to remove/recreate the certificate

class pontoon::service_certs (
    Stdlib::Fqdn $ca_server,
    Hash[String, Wmflib::Service] $services_config,
) {
    $service_names = pontoon::service_names($services_config)

    # Local Puppet CA
    $ca_manifest = {
        'pontoon_puppet_ca' => {
            'class_name' => 'puppet',
            'hostname' => $ca_server
        },
    }

    # The manifest for each requested service
    $services_manifest = $services_config.reduce({}) |$memo, $el| {
        $service = $el[0]
        $config = $el[1]

        $memo.merge(
            $service => {
                'authority' => 'pontoon_puppet_ca',
                'expiry'    => '6/6/6666',
                'key'       => {'algorithm' => 'ec'},
                'alt_names' => $service_names[$service],
            }
        )
    }

    $secrets_base = '/etc/puppet/private/modules/secret/secrets'
    $cergen_manifest = "${secrets_base}/certificates/certificates.manifests.d/pontoon.yaml"

    file { $cergen_manifest:
        content => to_yaml($services_manifest + $ca_manifest),
        notify  => [Exec['cergen pontoon'], Exec['git-commit secrets pontoon']],
    }

    exec { 'cergen pontoon':
        command     => "/usr/bin/cergen --base-path ${secrets_base}/certificates/ --generate ${cergen_manifest}",
        refreshonly => true,
    }

    exec { 'git-commit secrets pontoon':
        command     => 'git add . && git commit -m "Automatic commit from pontoon::service_certs"',
        refreshonly => true,
        provider    => shell,
        cwd         => $secrets_base,
    }

    # Make the SSL keypair available for each service name via symlinks
    $services_manifest.keys.each |$service| {
        $service_names[$service].each |$alt_name| {
            if defined(File["${secrets_base}/ssl/${alt_name}.key"]) {
                next()
            }

            file { "${secrets_base}/ssl/${alt_name}.key":
                ensure => 'link',
                target => "../certificates/${service}/${service}.key.private.pem",
                force  => yes,
                notify => Exec['git-commit secrets pontoon'],
            }

            file { "${secrets_base}/ssl/${alt_name}.crt":
                ensure => 'link',
                target => "../certificates/${service}/${service}.crt.pem",
                force  => yes,
                notify => Exec['git-commit secrets pontoon'],
            }
        }
    }
}
