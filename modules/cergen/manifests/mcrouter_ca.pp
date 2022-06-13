# SPDX-License-Identifier: Apache-2.0
class cergen::mcrouter_ca(String $ca_secret) {
    require ::cergen

    $manifests_dir = '/etc/cergen/mcrouter.manifests.d'

    file { $manifests_dir:
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0750',
    }

    # Manifests generator
    file { '/usr/local/sbin/mcrouter_generate_certs':
        source => 'puppet:///modules/cergen/mcrouter_generator.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0554',
    }

    file { "${manifests_dir}/mcrouter_ca.certs.yaml":
        content => template('cergen/mcrouter_ca.certs.yaml.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0400',
    }

    ensure_packages(['python3-cryptography', 'python3-git', 'python3-openssl'])

    file { '/usr/local/bin/renew_mcrouter_certs':
        source => 'puppet:///modules/cergen/renew_mcrouter_certs.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
