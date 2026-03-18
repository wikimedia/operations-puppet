# SPDX-License-Identifier: Apache-2.0

# mediabackup storage functionality exposes the api and store
# the files generated from and recovered to the media backup workers.

class profile::mediabackup::new_storage (
    Hash $mediabackup_config              = lookup('mediabackup'),
){
    $unix_user = 'objectstorage'
    $unix_group = 'objectstorage'
    $instances = ['00', '01', '02', '03']

    class { 'versitygw::storage_common':
        unix_user  => $unix_user,
        unix_group => $unix_group,
        config_dir => '/etc/versitygw',
        home_dir   => '/srv',
    }

    $tls_paths = profile::pki::get_cert('discovery', $facts['fqdn'], {
        'ensure'  => 'present',
        'owner'   => 'objectstorage',
        'outdir'  => '/etc/versitygw/ssl',
        'hosts'   => [$facts['hostname'], $facts['fqdn'], '127.0.0.1', '::1', 'localhost'],
        'require' => [ User[$unix_user], File['/etc/versitygw/ssl']],
    })

    $instances.each |Integer $index, String $instance| {
        $port = $mediabackup_config['storage_port'] + $index
        versitygw::storage { "${unix_user}${instance}":
            unix_user     => $unix_user,
            unix_group    => $unix_group,
            storage_path  => "/srv/${unix_user}${instance}",
            port          => $port,
            # console_port  => $mediabackup_config['console_port'],
            root_user     => $mediabackup_config['storage_root_user'],
            root_password => $mediabackup_config['storage_root_password'],
            cert_path     => $tls_paths['chained'],
            key_path      => $tls_paths['key'],
            ca_path       => $tls_paths['ca'],
        }

        # Do not open the firewall to everyone if there are no available worker hosts
        if length($mediabackup_config['worker_hosts']) > 0 {
            firewall::service { "versitygw-${unix_user}${instance}-mediabackup-workers":
                proto   => 'tcp',
                port    => $port,
                notrack => true,
                srange  => $mediabackup_config['worker_hosts'],
            }
        }
    }
}
