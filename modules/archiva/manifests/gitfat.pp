# == Class: archiva::gitfat
# Symlinks archiva artifacts to a git-fat store.
# This symlinks .jars to their shasums in a directory
# that git-fat can use as a source store.  A rsync
# server is started with a module that allows for
# reads from the git-fat store.
#
class archiva::gitfat {
    Class['::archiva'] -> Class['::archiva::gitfat']

    # The rsync daemon module will chroot to this directory
    $archiva_path            = '/var/lib/archiva'
    # git-fat symlinks will be created here.
    $archiva_gitfat_path     = "${archiva_path}/git-fat"

    # We want symlinks to be created with relative paths
    # so that the rsync daemon module's chroot will work
    # properly with symlinks.   All symlinks and targets
    # must be relative and within the rsync module for
    # this to work.  This path is relative to the
    # directory in which git-fat links are created
    # ($archiva_git_fat_path).
    $archiva_repository_path = '../repositories'

    file { $archiva_gitfat_path:
        ensure => 'directory',
        owner  => 'archiva',
        group  => 'archiva',
    }

    # install script to symlink archiva .jars into a git-fat store
    file { '/usr/local/bin/archiva-gitfat-link':
        source => 'puppet:///modules/archiva/archiva-gitfat-link',
        mode   => '0555',
    }

    # Periodically symlink .jar files
    # in $archiva_repository_path so that git-fat
    # can use them.
    cron { 'archiva-gitfat-link':
        # cd to the git-fat store so that links will be
        # created relative in this directory
        command => "cd ${archiva_gitfat_path} && /usr/local/bin/archiva-gitfat-link ${archiva_repository_path} . > /dev/null",
        minute  => '*/5',
        user    => 'archiva',
        require => File['/usr/local/bin/archiva-gitfat-link'],
    }

    # this uses modules/rsync to
    # set up an rsync daemon service
    include ::rsync::server

    # Set up an rsync module so that anybody
    # can rsync read from $gitfat_archiva_path.
    # The git fat store will be available at:
    #   hostname::archiva/git-fat
    rsync::server::module { 'archiva':
        path      => $archiva_path,
        read_only => 'yes',
        uid       => 'nobody',
        gid       => 'nogroup',
    }
}