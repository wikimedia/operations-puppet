# == Class jenkins::maintenance::compressconsolelogs
#
# Include this class to have console logs on master jenkins to be compressed
# via gzip.
#
class jenkins::maintenance::compressconsolelogs {

    cron { 'jenkins compress console logs':
        # File modified more than one day ago
        command => '/usr/bin/nice -n 19 /usr/bin/find /var/lib/jenkins/jobs -mtime +1 -path \'/var/lib/jenkins/jobs/*/builds/*/log\' -type f -exec gzip --best {} \;',
        user    => 'jenkins',
        weekday => '*',
        hour    => 3,
        minute  => 0,
    }

}
