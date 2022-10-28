# SPDX-License-Identifier: Apache-2.0
# mediabackup storage hosts expose the api and store
# the files generated from the media backup workers.
class profile::mediabackup::storage (
    Hash $mediabackup_config              = lookup('mediabackup'),
){
    $tls_paths = profile::pki::get_cert('discovery', $facts['fqdn'], {
        'ensure'  => 'present',
        'owner'   => 'minio-user',
        'outdir'  => '/etc/minio/ssl',
        'hosts'   => [$facts['hostname'], $facts['fqdn'], '127.0.0.1', '::1', 'localhost'],
        'notify'  => Service['minio'],
        'require' => [ User['minio-user'], File['/etc/minio/ssl']],
    })

    class { 'mediabackup::storage':
        storage_path  => $mediabackup_config['storage_path'],
        port          => $mediabackup_config['storage_port'],
        root_user     => $mediabackup_config['storage_root_user'],
        root_password => $mediabackup_config['storage_root_password'],
        cert_path     => $tls_paths['chained'],
        key_path      => $tls_paths['key'],
        ca_path       => $tls_paths['ca'],
    }
    nrpe::monitor_service { 'minio_server':
        description   => 'MinIO server processes',
        nrpe_command  => '/usr/lib/nagios/plugins/check_procs -c 1:1 -C minio -a server',
        critical      => false,
        contact_group => 'admins',
        notes_url     => 'https://wikitech.wikimedia.org/wiki/Media_storage/Backups',
    }

    # Do not open the firewall to everyone if there are no available storage hosts
    if length($mediabackup_config['worker_hosts']) > 0 {
        $workers = join($mediabackup_config['worker_hosts'], ' ')
        $srange_workers = join(['@resolve((', $workers, '))'], ' ')
        ferm::service { 'minio-mediabackup-workers':
            proto   => 'tcp',
            port    => $mediabackup_config['storage_port'],
            notrack => true,
            srange  => $srange_workers,
        }
    }
}
