# SPDX-License-Identifier: Apache-2.0
# == Class profile::statistics::explorer::misc_jobs
#
# This class is meant to collect crons/timers/scripts from
# various teams (Discovery, WMDE, etc..) that used to be run
# only on stat1007. Ideally in the future these jobs will be run
# on a dedicated VM or similar.
#
class profile::statistics::explorer::misc_jobs(
    String              $statsd_host     = lookup('statsd'),
    Array[Stdlib::Host] $labstore_hosts  = lookup('labstore_hosts'),
    Stdlib::Host        $graphite_host   = lookup('graphite_host'),
    Hash[String,String] $wmde_secrets    = lookup('wmde_secrets'),
    Array[String]       $hosts_with_jobs = lookup('profile::statistics::explorer::misc_jobs::hosts_with_jobs'),
) {

    if $::hostname in $hosts_with_jobs {
        # Performance team statistics scripts and cron jobs
        class { 'statistics::performance': }

        # WMDE releated statistics & analytics scripts.
        class { 'statistics::wmde':
            statsd_host   => $statsd_host,
            graphite_host => $graphite_host,
            wmde_secrets  => $wmde_secrets,
        }

        # Systemd timers owned by the Search team
        # (leveraging Analytics' refinery)
        include profile::analytics::search::jobs

        # Product Analytics team statistics scripts and cron jobs
        class { 'statistics::product_analytics': }

        # Allowing statistics nodes (mostly clouddb hosts in this case)
        # to push nginx access logs to a specific /srv path. We usually
        # allow only pull based rsyncs, but after T211330 we needed a way
        # to unbreak that use case. This rsync might be removed in the future.
        # TODO: this should be moved to hdfs-rsync.
        rsync::server::module { 'dumps-webrequest':
            path        => '/srv/log/webrequest/archive/dumps.wikimedia.org',
            read_only   => 'no',
            hosts_allow => $labstore_hosts,
            auto_ferm   => true,
        }
    }
}
