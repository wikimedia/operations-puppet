# === Class puppetmaster::rsync
#
# Simple class to allow syncing of the volatile and CA directories
#
class puppetmaster::rsync(
    $server,
    $cron_ensure='absent',
    Array[String] $frontends = [],
) {
    rsync::server::module {
        default:
            read_only   => 'yes',
            hosts_allow => $frontends,
            chroot      => false;
        'puppet_volatile':
            path => '/var/lib/puppet/volatile';
        'puppet_ca':
            path => '/var/lib/puppet/server/ssl/ca';
    }

    cron { 'sync_volatile':
        ensure  => $cron_ensure,
        command => "/usr/bin/rsync -avz --delete ${server}::puppet_volatile /var/lib/puppet/volatile > /dev/null 2>&1",
        minute  => '*/15',
    }

    cron { 'sync_ca':
        ensure  => $cron_ensure,
        command => "/usr/bin/rsync -avz --delete ${server}::puppet_ca /var/lib/puppet/server/ssl/ca > /dev/null 2>&1",
        hour    => '4',
    }
}
