# == Define dumps::web::fetches::analytics::job
#
# Regularly copies files from $hdfs_source to $local_destination.
# Uses hdfs-rsync, systemd timers and Kerberos.
#
# == Parameters
#
# [*hdfs_source*]
#   HDFS Source directory to pull data from.
#
# [*local_destination*]
#   Destination directory on local filesystem  to put data into.
#
# [*interval*]
#   Systemd interval that the timer will use.
#
# [*user*]
#   User running the Systemd timer.
#
# [*delete*]
#   Add the --delete if true.
#
# [*exclude*]
#   Add --exclude $value if not undef.
#
# [*ensure*]
#   Ensure status of systemd timer.
#
define dumps::web::fetches::analytics::job(
    String $hdfs_source,
    String $local_destination,
    String $interval,
    String $user,
    Boolean $delete = true,
    Boolean $ignore_missing_source = false,
    Wmflib::Ensure $ensure = present,
    Optional[String] $exclude = undef,
) {
    if !defined(File[$local_destination]) {
        file { $local_destination:
            ensure => 'directory',
            owner  => $user,
            group  => 'root',
        }
    }

    $delete_option = $delete ? {
        true    => '--delete',
        default => ''
    }

    # Quotes around the exclude value are on purpose to force
    # to parse it as a single value
    $exclude_option = $exclude ? {
        undef   => '',
        default => " --exclude \"${exclude}\""
    }

    # If $ignore_missing_source is enabled, add a check that prevents
    # hdfs-rsync to fail when the source directory is missing.
    $rsync_command = "/usr/local/bin/hdfs-rsync -r -t ${delete_option}${exclude_option} --chmod=go-w hdfs://${hdfs_source} file://${local_destination}"
    $ignore_msg = "Ignoring missing hdfs source hdfs://${hdfs_source}"
    $head = "#!/bin/bash\n"
    $script_content = $ignore_missing_source ? {
        true    => "${head}hdfs dfs -ls -d hdfs://${hdfs_source} > /dev/null 2>&1 && ${rsync_command} || echo ${ignore_msg}",
        default => "${head}${rsync_command}"
    }
    file { "/usr/local/bin/rsync-analytics-${title}":
        ensure  => $ensure,
        content => $script_content,
        mode    => '0550',
        owner   => $user,
        group   => 'root',
    }

    kerberos::systemd_timer { "analytics-dumps-fetch-${title}":
        description => "Copy ${title} files from Hadoop HDFS.",
        command     => "/usr/local/bin/rsync-analytics-${title}",
        interval    => $interval,
        user        => $user,
        require     => File["/usr/local/bin/rsync-analytics-${title}"],
    }
}
