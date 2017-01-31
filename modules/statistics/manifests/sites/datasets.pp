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
    $document_root = "${working_path}/datasets.wikimedia.org"

    file { [
        # /srv/datasets contains various datasets that are intended to be exposed publicly.
        $document_root,
        "${working_path}/public-datasets",
        "${working_path}/aggregate-datasets",
        "${working_path}/limn-public-data",
    ]:
        ensure => 'directory',
        owner  => 'root',
        group  => 'www-data',
        mode   => '0775',
    }

    # symlink $document_root/public-datasets to /srv/public-datasets
    file { "${document-root}/public-datasets":
        ensure => 'link',
        target => "${working_path}/public-datasets",
        owner  => 'root',
        group  => 'www-data',
    }

    # symlink $document_root/aggregate-datasets to /srv/aggregate-datasets
    file {  "${document_root}/aggregate-datasets":
        ensure => 'link',
        target => "${working_path}/aggregate-datasets",
        owner  => 'root',
        group  => 'www-data',
    }

    # symlink $document_root/limn-public-data to /srv/limn-public-data
    file {  "${document_root}/limn-public-data":
        ensure => 'link',
        target => "${working_path}/limn-public-data",
        owner  => 'root',
        group  => 'www-data',
    }

    # rsync from stat1003:/srv/public-datasets to $working_path/public-datasets
    cron { 'rsync public datasets':
        command => "/usr/bin/rsync -rt --delete stat1003.eqiad.wmnet::srv/public-datasets/* ${working_path}/public-datasets/",
        require => File["${working_path}/public-datasets"],
        user    => 'root',
        minute  => '*/30',
    }

    # rsync from stat1002:/srv/aggregate-datasets to $working_path/aggregate-datasets
    cron { 'rsync aggregate datasets from stat1002':
        command => "/usr/bin/rsync -rt --delete stat1002.eqiad.wmnet::srv/aggregate-datasets/* ${working_path}/aggregate-datasets/",
        require => File["${working_path}/aggregate-datasets"],
        user    => 'root',
        minute  => '*/30',
    }

    include ::apache::mod::headers
    apache::site { 'datasets':
        content => template('statistics/datasets.wikimedia.org.erb'),
        require => File[$document_root],
    }
}
