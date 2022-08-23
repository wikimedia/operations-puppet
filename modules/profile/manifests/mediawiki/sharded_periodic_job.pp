# SPDX-License-Identifier: Apache-2.0
# == define profile::mediawiki::sharded_periodic_job
#
# Helper to parallelize periodic_jobs by shard.
#
# == Parameters
#
# [*script*] The MW script to execute
#
# [*shards*] The shards to run against (e.g. ['s1'])
#
# [*interval*] The frequency with which the job must be executed, expressed as
#              one of the Calendar expressions accepted by systemd. See systemd.time(7)
#
# [*ensure*] Either 'present' or 'absent'. Default: present
#
define profile::mediawiki::sharded_periodic_job(
    String $script,
    Variant[
        Systemd::Timer::Interval,
        Systemd::Timer::Datetime
    ] $interval,
    Array[String] $shards = ['s1', 's2', 's3', 's4', 's5', 's6', 's7', 's8', 's11'],
    Wmflib::Ensure $ensure = present
) {
    $shards.map |$shard| {
        # For back-compat, support "s1@11" style shards
        $real_shard = regsubst($shard, '@.*', '')
        # Inject the dblist as the second argument (after the PHP script)
        $script = regsubst($script, '\.php', ".php ${real_shard}.dblist")

        profile::mediawiki::periodic_job { "${title}_${shard}":
            ensure   => $ensure,
            command  => "/usr/local/bin/mwscriptwikiset ${script}",
            interval => $interval,
        }
    }
}
