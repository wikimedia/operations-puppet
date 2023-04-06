# == Class zuul::monitoring::merger
#
# Icinga monitoring for the Zuul merger
#
# == Parameters
#
# [*ensure*]
#
class zuul::monitoring::merger (
    Wmflib::Ensure $ensure = present,
) {

    nrpe::monitor_service { 'zuul_merger':
        ensure        => $ensure,
        description   => 'zuul_merger_service_running',
        contact_group => 'contint',
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 --ereg-argument-array 'bin/zuul-merger'",
        notes_url     => 'https://www.mediawiki.org/wiki/Continuous_integration/Zuul',
    }

    nrpe::monitor_service { 'zuul_merger_git_daemon':
        ensure        => $ensure,
        description   => 'git_daemon_running',
        contact_group => 'contint',
        # git-daemon forks sub process with an extra parameter '--serve'
        # the regex ends with --syslog to ignore the forked child
        nrpe_command  => "/usr/lib/nagios/plugins/check_procs -w 1:1 -c 1:1 --ereg-argument-array '^/usr/lib/git-core/git-daemon --syslog'",
        notes_url     => 'https://www.mediawiki.org/wiki/Continuous_integration/Zuul',
    }

}
