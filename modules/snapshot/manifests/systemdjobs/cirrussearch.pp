class snapshot::systemdjobs::cirrussearch(
    $user      = undef,
    $filesonly = false,
) {
    $confsdir = $snapshot::dumps::dirs::confsdir
    $apachedir = $snapshot::dumps::dirs::apachedir

    file { '/var/log/cirrusdump':
        ensure => 'directory',
        mode   => '0644',
        owner  => $user,
    }

    $scriptpath = '/usr/local/bin/dumpcirrussearch.sh'
    file { $scriptpath:
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/systemdjobs/dumpcirrussearch.sh',
    }

    if !$filesonly {
        # The dumps take quite some time to complete. Split the dump up into
        # one process per dbshard. The dumps don't have anything to do with db
        # shards, but this is a convenient split of wikis with small wikis
        # grouped together and large wikis separated out. Shards 9 and 10 do
        # not exist (as of nov 2022).
        (range(1, 8) + [11]).each |$shard| {
            $dblist = "${apachedir}/dblists/s${shard}.dblist"
            systemd::timer::job { "cirrussearch-dump-s${shard}":
                ensure             => present,
                description        => 'Regular jobs to build snapshot of cirrus search',
                user               => $user,
                monitoring_enabled => false,
                send_mail          => true,
                environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
                command            => "${scriptpath} --config ${confsdir}/wikidump.conf.other --dblist ${dblist}",
                interval           => {'start' => 'OnCalendar', 'interval' => 'Mon *-*-* 16:15:0'},
                require            => [ File[$scriptpath], Class['snapshot::dumps::dirs'] ],
            }
        }
    }
}
