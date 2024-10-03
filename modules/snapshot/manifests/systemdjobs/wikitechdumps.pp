# SPDX-License-Identifier: Apache-2.0

class snapshot::systemdjobs::wikitechdumps(
    $user      = undef,
    $filesonly = false,
) {
    $systemdjobsdir = $snapshot::dumps::dirs::systemdjobsdir
    $repodir = $snapshot::dumps::dirs::repodir
    $confsdir = $snapshot::dumps::dirs::confsdir
    $minute = fqdn_rand(60)

    $scriptpath = '/usr/local/bin/wikitechdumps.sh'
    file { $scriptpath:
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/systemdjobs/wikitechdumps.sh',
    }

    if !$filesonly {
        systemd::timer::job { 'wikitech':
            ensure             => present,
            description        => 'Regular job to dump a snapshot of wikitech',
            user               => $user,
            monitoring_enabled => false,
            send_mail          => false,
            environment        => {'MAILTO' => 'sre-service-ops@wikimedia.org'},
            working_directory  => $repodir,
            command            => "${scriptpath} ${systemdjobsdir}/wikitech",
            interval           => {'start' => 'OnCalendar', 'interval' => "*-*-* 1:${minute}:00"},
        }
    }
}
