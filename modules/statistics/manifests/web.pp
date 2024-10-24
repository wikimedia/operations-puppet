# == Class statistics::web
# Common things needed for a statistics webserver node.
# This should be included if you want to include any
# sites in statistics::sites
class statistics::web {
    Class['::statistics'] -> Class['::statistics::web']

    # make sure /var/log/apache2 is readable by wikidevs for debugging.
    # This won't make the actual log files readable, only the directory.
    # Individual log files can be created and made readable by
    # classes that manage individual sites.
    file { '/var/log/apache2':
        ensure => 'directory',
        owner  => 'root',
        group  => 'wikidev',
        mode   => '0750',
    }

    ensure_packages([
        'mc',
        'unzip',
        'zip',
    ])

    # Install hardsync shell script.
    # This allows us to present the contents of multiple source directories
    # in a single directory by hardlink copying the files into the destination.
    # This is mainly used so dataset files from multiple stat* boxes can
    # be published in a single directory.  See: T125854
    file { '/usr/local/bin/hardsync':
        source => 'puppet:///modules/statistics/hardsync.sh',
        mode   => '0755',
        owner  => 'root',
        group  => 'root',
    }

    # Allow rsyncing from statistics::servers
    # NOTE: This does not set up any rsync modules; that must be done
    # in other classes.
    class { '::rsync::server':
        # the default timeout of 300 is too low
        timeout => 1000,
    }

    profile::auto_restarts::service { 'rsync': }
}
