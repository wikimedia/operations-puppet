# == Class profile::statistics::explorer::misc_jobs
#
# This class is meant to collect crons/timers/scripts from
# various teams (Discovery, WMDE, etc..) that used to be run
# only on stat1007. Ideally in the future these jobs will be run
# on a dedicated VM or similar.
#
class profile::statistics::explorer::misc_jobs(
    $statsd_host         = lookup('statsd'),
    $graphite_host       = lookup('profile::statistics::explorer::misc_jobs::graphite_host'),
    $wmde_secrets        = lookup('wmde_secrets'),
    $use_kerberos        = lookup('profile::statistics::explorer::misc_jobs::use_kerberos', { 'default_value' => false }),
    $hosts_with_jobs     = lookup('profile::statistics::explorer::misc_jobs::hosts_with_jobs'),
) {

    if $::hostname in $hosts_with_jobs {
        # Discovery team statistics scripts and cron jobs
        class { '::statistics::discovery':
            use_kerberos => $use_kerberos
        }

        # WMDE releated statistics & analytics scripts.
        class { '::statistics::wmde':
            statsd_host   => $statsd_host,
            graphite_host => $graphite_host,
            wmde_secrets  => $wmde_secrets,
        }
    }
}
