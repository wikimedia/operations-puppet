class mediawiki::jobqueue(
    $run_jobs_enabled,
    $user                   = 'apache',
    $type                   = '',
    $nice                   = 20,
    $script                 = '/usr/local/bin/jobs-loop.sh',
    $pid_file               = '/var/run/mw-jobs.pid',
    $timeout                = 300,
    $extra_args             = '',
    $dprioprocs             = 5,
    $iprioprocs             = 5,
    $procs_per_iobound_type = 1
) {
    deployment::target { 'jobrunner': }

    file { '/etc/init.d/mw-job-runner':
        owner  => 'root',
        group  => 'root',
        mode   => '0755',
        source => 'puppet:///modules/mediawiki/jobqueue/mw-job-runner.init',
        notify => Service['mw-job-runner'],
    }

    file { '/etc/default/mw-job-runner':
        content => template('mediawiki/jobqueue/mw-job-runner.default.erb'),
        notify  => Service['mw-job-runner'],
    }

    file { '/usr/local/bin/jobs-loop.sh':
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => template('mediawiki/jobqueue/jobs-loop.sh.erb'),
        notify  => Service['mw-job-runner'],
    }

    $jobrunnerstatus = $run_jobs_enabled ? {
        true    => running,
        default => stopped,
    }

    service { 'mw-job-runner':
        ensure    => $jobrunnerstatus,
        hasstatus => false,
        pattern   => $script,
    }

    # Manage gradual runner pipeline shrink bug
    # we restart jobs every hour, trying to evenly randomize the restart time.
    cron { 'mw-job-restarter':
        command => 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin" /etc/init.d/mw-job-runner restart > /dev/null',
        user    => 'root',
        minute  => inline_template('<%= [@uniqueid].pack("H*").unpack("L")[0] % 60 -%>'),
        hour    => '*',
        ensure  => $run_jobs_enabled ? {
            true    => present,
            default => absent,
        }
    }
}
