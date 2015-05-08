# == Class statistics::sites::datasets
# datasets.wikimedia.org
#
# TODO: Parameterize rsync source hostnames
#
# NOTE: This class has nothing to do with the
# dataset1001 datasets_mount.
#
class statistics::sites::datasets {
    require statistics::web

    $working_path = $::statistics::working_path
    file { [
        "${working_path}/public-datasets",
        "${working_path}/aggregate-datasets"
    ]:
        ensure => 'directory',
        owner  => 'root',
        group  => 'www-data',
        mode   => '0640',
    }

    # symlink /var/www/public-datasets to $working_path/public-datasets
    file { '/var/www/public-datasets':
        ensure => 'link',
        target => "${working_path}/public-datasets",
        owner  => 'root',
        group  => 'www-data',
        mode   => '0640',
    }

    # symlink /var/www/aggregate-datasets to $working_path/aggregate-datasets
    file { '/var/www/aggregate-datasets':
        ensure => 'link',
        target => "${working_path}/aggregate-datasets",
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

    # rsync from fluorine:/srv/aggregate-datasets to $working_path/aggregate-datasets
    cron { 'rsync aggregate datasets from fluorine':
        command => "/usr/bin/rsync -rt --delete fluorine.eqiad.wmnet::srv/public-datasets/* ${working_path}/public-datasets/",
        require => File["${working_path}/public-datasets"],
        user    => 'root',
        minute  => '*/30',
    }

    include apache::mod::headers
    apache::site { 'datasets':
        source  => 'puppet:///modules/statistics/datasets.wikimedia.org',
    }
}
