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
# [*use_kerberos*]
#   Authenticate via Kerberos before executing
#   the systemd timer.
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
    Boolean $use_kerberos = false,
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

    kerberos::systemd_timer { "analytics-dumps-fetch-${title}":
        description  => "Copy ${title} files from Hadoop HDFS.",
        command      => "/bin/bash -c '/usr/local/bin/hdfs-rsync -r -t ${delete_option}${exclude_option} --chmod=go-w hdfs://${hdfs_source} file://${local_destination}'",
        interval     => $interval,
        user         => $user,
        use_kerberos => $use_kerberos,
    }
}


