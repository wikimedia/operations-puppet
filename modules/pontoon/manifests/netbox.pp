# SPDX-License-Identifier: Apache-2.0
class pontoon::netbox (
  String $base_dir,
) {
    $repo_dir = "${base_dir}/netbox-hiera"

    # XXX refactor to use profile::puppetserver::git instead
    git::clone { 'netbox-hiera':
        ensure    => 'latest',
        origin    => 'https://netbox-exports.wikimedia.org/netbox-hiera',
        owner     => 'puppet',
        mode      => '0755',
        directory => $repo_dir,
    }

    file { '/etc/puppet/netbox':
        ensure => link,
        target => $repo_dir,
    }

    # Pretend all hosts have the same netbox data
    # The values are used as placeholders/dummies, this class can be expanded to
    # be able to override specific values if the need ever arises.
    $host_data = {
        'profile::netbox::host::location' => {
            'rack' => 'B1',
            'row'  => 'eqiad-row-b',
            'site' => 'eqiad',
        },
        'profile::netbox::host::status'   => 'active',
    }

    pontoon::hosts().each |$fqdn| {
        $host = split($fqdn, '\.')[0]

        file { "${repo_dir}/hosts/${host}.yaml":
            content => to_yaml($host_data),
        }
    }
}
