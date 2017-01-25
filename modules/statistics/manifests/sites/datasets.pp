# == Class statistics::sites::datasets
# datasets.wikimedia.org
#
# TODO: Parameterize rsync source hostnames
#
# NOTE: This class has nothing to do with the
# dataset1001 datasets_mount.
#
class statistics::sites::datasets {
    require ::statistics::web

    # $working_path should be /srv
    $working_path = $::statistics::working_path
    # TODO: This site will be deprecated and redirected from analytics.wm.org as part of T132594.
    $document_root = "${working_path}/datasets"

    file { [
        # /srv/datasets contains various datasets that are intended to be exposed publicly.
        $document_root,
        # TODO: These subdirs will be moved to common/legacy as part of T125854.
        "${document_root}/public-datasets",
        "${document_root}/aggregate-datasets",
        "${document_root}/limn-public-data",
    ]:
        ensure => 'directory',
        owner  => 'root',
        group  => 'www-data',
        mode   => '0775',
    }

    # TODO: These Symlinks from /srv/* -> /srv/datasets/* should be removed as part of T125854
    # symlink /srv/public-datasets to $working_path/datasets/public-datasets
    file { "${working_path}/public-datasets":
        ensure => 'link',
        target => "${document_root}/public-datasets",
        owner  => 'root',
        group  => 'www-data',
    }

    # symlink /srv/aggregate-datasets to $working_path/datasets/aggregate-datasets
    file {  "${working_path}/aggregate-datasets":
        ensure => 'link',
        target => "${document_root}/aggregate-datasets",
        owner  => 'root',
        group  => 'www-data',
    }

    # symlink /srv/limn-public-data to $working_path/datasets/limn-public-data
    file {  "${working_path}/limn-public-data":
        ensure => 'link',
        target => "${working_path}/datasets/limn-public-data",
        owner  => 'root',
        group  => 'www-data',
    }


    # rsync from stat1003:/srv/public-datasets to $working_path/public-datasets
    cron { 'rsync public datasets':
        command => "/usr/bin/rsync -rt --delete stat1003.eqiad.wmnet::srv/public-datasets/* ${document_root}/public-datasets/",
        require => File["${document_root}/public-datasets"],
        user    => 'root',
        minute  => '*/30',
    }

    # rsync from stat1002:/srv/aggregate-datasets to $working_path/aggregate-datasets
    cron { 'rsync aggregate datasets from stat1002':
        command => "/usr/bin/rsync -rt --delete stat1002.eqiad.wmnet::srv/aggregate-datasets/* ${document_root}/aggregate-datasets/",
        require => File["${document_root}/aggregate-datasets"],
        user    => 'root',
        minute  => '*/30',
    }

    include ::apache::mod::headers
    apache::site { 'datasets':
        content => template('statistics/datasets.wikimedia.org.erb'),
        require => File[$document_root],
    }
}
