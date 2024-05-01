class dumps::web::fetches::stats(
    $src_hdfs = undef,
    $miscdatasetsdir = undef,
    $user = undef,
) {
    # Each of these jobs have a readme.html file rendered by  dumps::web::html.
    # We need to make sure the rsync --delete does not delete these files
    # which are put in place on the local destination host by puppet.
    Hdfs_tools::Hdfs_rsync_job {
        exclude => 'readme.html'
    }

    # Copies over mediacounts files from HDFS archive
    hdfs_tools::hdfs_rsync_job { 'mediacounts':
        hdfs_source       => "${src_hdfs}/mediacounts/",
        local_destination => "${miscdatasetsdir}/mediacounts/",
        interval          => '*-*-* *:41:00',
        user              => $user,
    }

    # Copies over files with pageview statistics per page and project,
    # using the current definition of pageviews, from HDFS archive
    hdfs_tools::hdfs_rsync_job { 'pageview':
        hdfs_source       => "${src_hdfs}/{pageview,projectview}/legacy/hourly/",
        local_destination => "${miscdatasetsdir}/pageviews/",
        interval          => '*-*-* *:51:00',
        user              => $user,
    }

    # Copies over files with unique devices statistics per project,
    # using the last access cookie method, from HDFS archive
    hdfs_tools::hdfs_rsync_job { 'unique_devices':
        hdfs_source       => "${src_hdfs}/unique_devices/",
        local_destination => "${miscdatasetsdir}/unique_devices/",
        interval          => '*-*-* *:31:00',
        user              => $user,
    }

    # Copies over clickstream files from HDFS archive
    hdfs_tools::hdfs_rsync_job { 'clickstream':
        hdfs_source       => "${src_hdfs}/clickstream/",
        local_destination => "${miscdatasetsdir}/clickstream/",
        interval          => '*-*-* *:04:00',
        user              => $user,
    }

    # Copies over mediawiki history dumps from HDFS archive
    # Copying only the last 2 dumps explicitely
    # --delete will take care of deleting old ones
    # Dates portions of the command are extracted as variables for reusability
    $date1_cmd = "\$(/bin/date --date=\"\$(/bin/date +%Y-%m-15) -1 month\" +\"%Y-%m\")"
    $date2_cmd = "\$(/bin/date --date=\"\$(/bin/date +%Y-%m-15) -2 month\" +\"%Y-%m\")"
    hdfs_tools::hdfs_rsync_job { 'mediawiki_history_dumps':
        hdfs_source           => "${src_hdfs}/mediawiki/history/{${date1_cmd},${date2_cmd}}",
        local_destination     => "${miscdatasetsdir}/mediawiki_history/",
        interval              => '*-*-* 05:00:00',
        user                  => $user,
        ignore_missing_source => true,
    }

    # Copies over geoeditors dumps from HDFS archive
    hdfs_tools::hdfs_rsync_job { 'geoeditors_dumps':
        hdfs_source       => "${src_hdfs}/geoeditors/public/",
        local_destination => "${miscdatasetsdir}/geoeditors/",
        interval          => '*-*-* 06:00:00',
        user              => $user,
    }

    # Copies over pageview complete daily dumps from HDFS archive
    hdfs_tools::hdfs_rsync_job { 'pageview_complete_dumps':
        hdfs_source       => "${src_hdfs}/pageview/complete/",
        local_destination => "${miscdatasetsdir}/pageview_complete/",
        interval          => '*-*-* 05:00:00',
        user              => $user,
    }

    # Copies over commons impact metrics dumps from HDFS archive
    hdfs_tools::hdfs_rsync_job { 'commons_impact_metrics':
        hdfs_source       => "${src_hdfs}/commons/",
        local_destination => "${miscdatasetsdir}/commons/",
        interval          => '*-*-* 06:00:00',
        user              => $user,
    }
}
