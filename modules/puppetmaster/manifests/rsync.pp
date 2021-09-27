# === Class puppetmaster::rsync
#
# Simple class to allow syncing of the volatile and CA directories
#
class puppetmaster::rsync(
    String $server,
    Wmflib::Ensure $cron_ensure = 'absent',
    Array[String] $frontends = [],
){

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
        ensure  => absent,
        command => "/usr/bin/rsync -avz --delete ${server}::puppet_volatile /var/lib/puppet/volatile > /dev/null 2>&1",
        minute  => '*/15',
    }

    systemd::timer::job { 'sync-puppet-volatile':
        ensure             => $cron_ensure,
        user               => 'root',
        description        => 'rsync puppet volatile data to another server',
        command            => "/usr/bin/rsync -avz --delete ${server}::puppet_volatile /var/lib/puppet/volatile",
        interval           => {'start' => 'OnUnitInactiveSec', 'interval' => '15m'},
        monitoring_enabled => false,
        logging_enabled    => false,
    }

    cron { 'sync_ca':
        ensure  => absent,
        command => "/usr/bin/rsync -avz --delete ${server}::puppet_ca /var/lib/puppet/server/ssl/ca > /dev/null 2>&1",
        hour    => '4',
    }

    systemd::timer::job { 'sync-puppet-ca':
        ensure             => $cron_ensure,
        user               => 'root',
        description        => 'rsync puppet CA data to another server',
        command            => "/usr/bin/rsync -avz --delete ${server}::puppet_ca /var/lib/puppet/server/ssl/ca",
        interval           => {'start' => 'OnUnitInactiveSec', 'interval' => 'daily'},
        monitoring_enabled => false,
        logging_enabled    => false,
    }
}
