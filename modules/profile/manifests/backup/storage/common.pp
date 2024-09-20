# Profile class for adding a storage daemon service to a host

class profile::backup::storage::common(
    $director = lookup('profile::backup::director'),
) {
    include profile::firewall
    include profile::base::production

    class { 'bacula::storage':
        director           => $director,
        sd_max_concur_jobs => 5,
        sqlvariant         => 'mysql',
    }

    nrpe::monitor_service { 'bacula_sd':
        description  => 'bacula sd process',
        nrpe_command => '/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 -u bacula -C bacula-sd',
        notes_url    => 'https://wikitech.wikimedia.org/wiki/Bacula',
    }

    firewall::service { 'bacula-storage-demon':
        proto    => 'tcp',
        port     => 9103,
        src_sets => ['PRODUCTION_NETWORKS'],
    }
}
