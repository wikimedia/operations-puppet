# SPDX-License-Identifier: Apache-2.0
class snapshot::dumps::dump_fillin_wd(
    $enable         = true,
    $user           = undef,
    $maxjobs        = undef,
    $parts_startend = undef,
) {
    if ($enable) {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    file { '/usr/local/bin/dumps_fillin_wd.sh':
        ensure => 'present',
        path   => '/usr/local/bin/dumps_fillin_wd.sh',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/snapshot/dumps/dumps_fillin_wd.sh',
    }

    file { '/var/log/dumps':
      ensure => 'directory',
      path   => '/var/log/dumps',
      mode   => '0755',
      owner  => $user,
    }

    # fixme config file path is hardcoded in, yuck
    # it's not awesome to have the start end days hardcoded in here either
    # the files needed as input to this script are ready early UTC on the 6th, so starting on the 7th should be
    # ok for some time
    # the end date is chosen depending on the part range we run, leaving a little time for automated
    # reruns in case of transient errors, but finishing up well before the regular dump worker would
    # try to run these same parts
    $command_args = "--startday 07 --endday 11 --numjobs ${maxjobs} --jobinfo ${parts_startend} --wiki wikidatawiki"
    systemd::timer::job { 'dumps_fillin_wd':
        ensure             => present,
        description        => 'snapshot - full dumps - fillin - wikidata',
        user               => $user,
        monitoring_enabled => false,
        send_mail          => true,
        environment        => {'MAILTO' => 'ops-dumps@wikimedia.org'},
        command            => "/usr/bin/bash /usr/local/bin/dumps_fillin_wd.sh ${command_args} --config /etc/dumps/confs/wikidump.conf.dumps:wd",
        interval           => {'start' => 'OnCalendar', 'interval' => '*-*-07..11 08,20:05:00'},
    }
}
