# == Define dumps::web::fetches::analytics::job
#
# Regularly copies files from $source to $destination.
# Supports systemd timers and Kerberos.
#
# == Parameters
#
# [*source*]
#   Source directory to pull data from.
#
# [*destination*]
#   Destination directory to put data into.
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
    String $source,
    String $destination,
    String $interval,
    String $user,
    Boolean $delete = true,
    Boolean $use_kerberos = false,
    Wmflib::Ensure $ensure = present,
    Optional[String] $exclude = undef,
    Boolean $use_hdfs_rsync = false,
) {
    if !defined(File[$destination]) {
        file { $destination:
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

    $command = $use_hdfs_rsync ? {
        true    => "/bin/bash -c '/usr/local/bin/hdfs-rsync -r -t ${delete_option}${exclude_option} --chmod=go-w hdfs://${source} file://${destination}'",
        default => "/bin/bash -c '/usr/bin/rsync -rt ${delete_option}${exclude_option} --chmod=go-w ${source}/ ${destination}/'"
    }

    kerberos::systemd_timer { "analytics-dumps-fetch-${title}":
        description  => "Copy ${title} files from Hadoop HDFS.",
        command      => $command,
        interval     => $interval,
        user         => $user,
        use_kerberos => $use_kerberos,
    }
}


