# application server required cron jobs
# vim: set ts=4 sw=4 et:
class applicationserver::cron {
    cron { 'cleanupipc':
        ensure  => present,
        command => 'ipcs -s | grep apache | cut -f 2 -d \\  | xargs -rn 1 ipcrm -s',
        user    => 'root',
        minute  => 26,
    }
    cron { 'cleantmpphp':
        ensure  => present,
        command => "find /tmp -name 'php*' -type f -ctime +1 -exec rm -f {} \\;",
        user    => 'root',
        hour    => 5,
        minute  => 0,
    }
    cron { 'bug55541':   # Hack! Fix the bug and kill this job. --Ori
        ensure  => present,
        command => 'find /tmp -name \*.tif -mmin +60  -delete',
        user    => 'root',
        minute  => 34,
    }
}
