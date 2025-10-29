# == Class: dumps::web::fetches::stats
#
# === Parameters:
# [*src_hdfs_archive*]
#   Archive directory to source from. These datasets are meant for archival,
#   with the intent to never delete.
#
# [*src_hdfs_exports*]
#   Exports directory to source from. These datasets are meant for file exports
#   that are temporal, with the intent to keep just the last N.
#
# [*miscdatasetsdir*]
#   The local destination to sync datasets to.
#
# [*user*]
#   The unix user to perform the sync as.
class dumps::web::fetches::stats(
    $src_hdfs_archive = undef,
    $src_hdfs_exports = undef,
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
        hdfs_source       => "${src_hdfs_archive}/mediacounts/",
        local_destination => "${miscdatasetsdir}/mediacounts/",
        interval          => '*-*-* *:41:00',
        user              => $user,
    }

    # Copies over files with pageview statistics per page and project,
    # using the current definition of pageviews, from HDFS archive
    hdfs_tools::hdfs_rsync_job { 'pageview':
        hdfs_source       => "${src_hdfs_archive}/{pageview,projectview}/legacy/hourly/",
        local_destination => "${miscdatasetsdir}/pageviews/",
        interval          => '*-*-* *:51:00',
        user              => $user,
    }

    # Copies over files with unique devices statistics per project,
    # using the last access cookie method, from HDFS archive
    hdfs_tools::hdfs_rsync_job { 'unique_devices':
        hdfs_source       => "${src_hdfs_archive}/unique_devices/",
        local_destination => "${miscdatasetsdir}/unique_devices/",
        interval          => '*-*-* *:31:00',
        user              => $user,
    }

    # Copies over clickstream files from HDFS archive
    hdfs_tools::hdfs_rsync_job { 'clickstream':
        hdfs_source       => "${src_hdfs_archive}/clickstream/",
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
        hdfs_source           => "${src_hdfs_archive}/mediawiki/history/{${date1_cmd},${date2_cmd}}",
        local_destination     => "${miscdatasetsdir}/mediawiki_history/",
        interval              => '*-*-* 05:00:00',
        user                  => $user,
        ignore_missing_source => true,
    }

    # Copies over geoeditors dumps from HDFS archive
    hdfs_tools::hdfs_rsync_job { 'geoeditors_dumps':
        hdfs_source       => "${src_hdfs_archive}/geoeditors/public/",
        local_destination => "${miscdatasetsdir}/geoeditors/",
        interval          => '*-*-* 06:00:00',
        user              => $user,
    }

    # Copies over pageview complete daily dumps from HDFS archive
    hdfs_tools::hdfs_rsync_job { 'pageview_complete_dumps':
        hdfs_source       => "${src_hdfs_archive}/pageview/complete/",
        local_destination => "${miscdatasetsdir}/pageview_complete/",
        interval          => '*-*-* 05:00:00',
        user              => $user,
    }

    # Copies over commons impact metrics dumps from HDFS archive
    hdfs_tools::hdfs_rsync_job { 'commons_impact_metrics':
        hdfs_source       => "${src_hdfs_archive}/commons/",
        local_destination => "${miscdatasetsdir}/commons_impact_metrics/",
        interval          => '*-*-* 06:00:00',
        user              => $user,
    }

    # Copies over cirrus index dumps from HDFS archive
    hdfs_tools::hdfs_rsync_job { 'cirrus_index_dumps':
        hdfs_source       => "${src_hdfs_exports}/cirrus-search-index/",
        local_destination => "${miscdatasetsdir}/cirrus_search_index",
        interval          => '*-*-* 05:00:00',
        user              => $user,
    }

    # Copies over MediaWiki Content History from HDFS exports
    hdfs_tools::hdfs_rsync_job { 'mediawiki_content_history':
      hdfs_source       => "${src_hdfs_exports}/mediawiki_content_history/",
      local_destination => "${miscdatasetsdir}/mediawiki_content_history/",
      interval          => '*-*-* 07:00:00',
      user              => $user,
    }

    # Copies over MediaWiki Content Current from HDFS exports
    hdfs_tools::hdfs_rsync_job { 'mediawiki_content_current':
      hdfs_source       => "${src_hdfs_exports}/mediawiki_content_current/",
      local_destination => "${miscdatasetsdir}/mediawiki_content_current/",
      interval          => '*-*-* 08:00:00',
      user              => $user,
    }
}
