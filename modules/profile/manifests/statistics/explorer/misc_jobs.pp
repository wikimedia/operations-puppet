# SPDX-License-Identifier: Apache-2.0
# == Class profile::statistics::explorer::misc_jobs
#
# This class is meant to collect crons/timers/scripts from
# various teams (Discovery, WMDE, etc..) that run only on
# stat1011. Ideally in the future these jobs will be run
# on a dedicated VM or similar.
#
class profile::statistics::explorer::misc_jobs (
    String              $statsd_host     = lookup('statsd'),
    Array[Stdlib::Host] $labstore_hosts  = lookup('labstore_hosts'),
    Stdlib::Host        $graphite_host   = lookup('graphite_host'),
    Hash[String,String] $wmde_secrets    = lookup('wmde_secrets'),
    Array[String]       $hosts_with_jobs = lookup('profile::statistics::explorer::misc_jobs::hosts_with_jobs'),
) {
    if $facts['networking']['hostname'] in $hosts_with_jobs {
        # Performance team statistics scripts and cron jobs
        class { 'statistics::performance': }

        # WMDE releated statistics & analytics scripts.
        class { 'statistics::wmde':
            statsd_host   => $statsd_host,
            graphite_host => $graphite_host,
            wmde_secrets  => $wmde_secrets,
        }

        # Product Analytics team statistics scripts and cron jobs
        class { 'statistics::product_analytics': }

        # Allowing statistics nodes (mostly clouddb hosts in this case)
        # to push nginx access logs to a specific /srv path. We usually
        # allow only pull based rsyncs, but after T211330 we needed a way
        # to unbreak that use case. This rsync might be removed in the future.
        # TODO: this should be moved to hdfs-rsync.
        $weblog_dump_path = '/srv/log/webrequest/archive/dumps.wikimedia.org'

        $weblog_dump_dirs = [
            '/srv/log/webrequest',
            '/srv/log/webrequest/archive',
            $weblog_dump_path,
        ]
        file { $weblog_dump_dirs:
            ensure => directory,
        }
        rsync::server::module { 'dumps-webrequest':
            path          => $weblog_dump_path,
            read_only     => 'no',
            hosts_allow   => $labstore_hosts,
            auto_firewall => true,
        }
        systemd::timer::job { 'clean-dumps-webrequest':
            description => 'Clean old dumps webrequest log files',
            user        => 'root',
            interval    => {
                'start'    => 'OnCalendar',
                'interval' => 'daily',
            },
            command     => "/usr/bin/find ${weblog_dump_path} -type f -mtime +90 -delete",
        }
    }
}
