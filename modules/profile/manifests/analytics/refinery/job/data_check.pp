# == Class profile::analytics::refinery::job::data_check
# Configures cron jobs that send email about the faultyness of webrequest data
#
# These checks walk HDFS through the plain file system.
#
class profile::analytics::refinery::job::data_check {
    require ::profile::analytics::refinery

    # This should not be hardcoded.  Instead, one should be able to use
    # $::cdh::hadoop::mount::mount_point to reference the user supplied
    # parameter when the cdh::hadoop::mount class is evaluated.
    # I am not sure why this is not working.
    $hdfs_mount_point = '/mnt/hdfs'

    $mail_to = 'analytics-alerts@wikimedia.org'

    # Since the 'stats' user is not in ldap, it is unnecessarily hard
    # to grant it access to the private data in hdfs. As discussed in
    #   https://gerrit.wikimedia.org/r/#/c/186254
    # the cron runs as hdfs instead.
    cron { 'refinery data check hdfs_mount':
        command     => "${::profile::analytics::refinery::path}/bin/refinery-dump-status-webrequest-partitions --hdfs-mount ${hdfs_mount_point} --datasets webrequest,raw_webrequest --quiet --percent-lost",
        environment => "MAILTO=${mail_to}",
        user        => 'hdfs',
        hour        => 10,
        minute      => 0,
    }

    cron { 'refinery data check pageviews':
        command     => "${::profile::analytics::refinery::path}/bin/refinery-dump-status-webrequest-partitions --hdfs-mount ${hdfs_mount_point} --datasets pageview,projectview --quiet",
        environment => "MAILTO=${mail_to}",
        user        => 'hdfs', # See comment in first cron above
        hour        => 10,
        minute      => 10,
    }
}