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
    $document_root = "${working_path}/datasets.wikimedia.org"

    file { [
        "${working_path}/public-datasets",
        "${working_path}/aggregate-datasets",
        "${working_path}/limn-public-data",
    ]:
        ensure => 'directory',
        owner  => 'root',
        group  => 'www-data',
        mode   => '0750',
    }

    file { $document_root:
        ensure => 'directory',
        owner  => 'root',
        group  => 'www-data',
        mode   => '0755',
    }


    # symlink datasets.wikimedia.org/public-datasets to $working_path/public-datasets
    file { "${document_root}/public-datasets":
        ensure => 'link',
        target => "${working_path}/public-datasets",
        owner  => 'root',
        group  => 'www-data',
        mode   => '0640',
    }

    # symlink datasets.wikimedia.org/aggregate-datasets to $working_path/aggregate-datasets
    file {  "${document_root}/aggregate-datasets":
        ensure => 'link',
        target => "${working_path}/aggregate-datasets",
        owner  => 'root',
        group  => 'www-data',
        mode   => '0640',
    }

    # symlink datasets.wikimedia.org/limn-public-data to $working_path/limn-public-data
    file {  "${document_root}/limn-public-data":
        ensure => 'link',
        target => "${working_path}/limn-public-data",
        owner  => 'root',
        group  => 'www-data',
        mode   => '0640',
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
        source  => 'puppet:///modules/statistics/datasets.wikimedia.org',
    }
}
