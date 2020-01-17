class dumps::web::fetches::stats(
    $src_hdfs = undef,
    $miscdatasetsdir = undef,
    $user = undef,
    $use_kerberos = false,
) {
    # Each of these jobs have a readme.html file rendered by  dumps::web::html.
    # We need to make sure the rsync --delete does not delete these files
    # which are put in place on the local destination host by puppet.
    Dumps::Web::Fetches::Analytics::Job {
        exclude => 'readme.html'
    }

    # Copies over mediacounts files from HDFS archive
    dumps::web::fetches::analytics::job { 'mediacounts':
        hdfs_source       => "${src_hdfs}/mediacounts/",
        local_destination => "${miscdatasetsdir}/mediacounts/",
        interval          => '*-*-* *:41:00',
        user              => $user,
        use_kerberos      => $use_kerberos,
    }

    # Copies over files with pageview statistics per page and project,
    # using the current definition of pageviews, from HDFS archive
    dumps::web::fetches::analytics::job { 'pageview':
        hdfs_source       => "${src_hdfs}/{pageview,projectview}/legacy/hourly/",
        local_destination => "${miscdatasetsdir}/pageviews/",
        interval          => '*-*-* *:51:00',
        user              => $user,
        use_kerberos      => $use_kerberos,
    }

    # Copies over files with unique devices statistics per project,
    # using the last access cookie method, from HDFS archive
    dumps::web::fetches::analytics::job { 'unique_devices':
        hdfs_source       => "${src_hdfs}/unique_devices/",
        local_destination => "${miscdatasetsdir}/unique_devices/",
        interval          => '*-*-* *:31:00',
        user              => $user,
        use_kerberos      => $use_kerberos,
    }

    # Copies over clickstream files from HDFS archive
    dumps::web::fetches::analytics::job { 'clickstream':
        hdfs_source       => "${src_hdfs}/clickstream/",
        local_destination => "${miscdatasetsdir}/clickstream/",
        interval          => '*-*-* *:04:00',
        user              => $user,
        use_kerberos      => $use_kerberos,
    }

    # Copies over mediawiki history dumps from HDFS archive
    # Copying only the last 2 dumps explicitely
    # --delete will take care of deleting old ones
    # Dates portions of the command are extracted as variables for reusability
    $date1_cmd = "\$\$(/bin/date --date=\"\$\$(/bin/date +%%Y-%%m-15) -1 month\" +\"%%Y-%%m\")"
    $date2_cmd = "\$\$(/bin/date --date=\"\$\$(/bin/date +%%Y-%%m-15) -2 month\" +\"%%Y-%%m\")"
    dumps::web::fetches::analytics::job { 'mediawiki_history_dumps':
        hdfs_source       => "${src_hdfs}/mediawiki/history/{${date1_cmd},${date2_cmd}}",
        local_destination => "${miscdatasetsdir}/mediawiki_history/",
        interval          => '*-*-* 05:00:00',
        user              => $user,
        use_kerberos      => $use_kerberos,
    }

    # Copies over geoeditors dumps from HDFS archive
    dumps::web::fetches::analytics::job { 'geoeditors_dumps':
        hdfs_source       => "${src_hdfs}/geoeditors/public/",
        local_destination => "${miscdatasetsdir}/geoeditors/",
        interval          => '*-*-* 06:00:00',
        user              => $user,
        use_kerberos      => $use_kerberos,
    }
}
