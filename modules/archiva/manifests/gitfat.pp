# == Class: archiva::gitfat
# Symlinks archiva artifacts to a git-fat store.
# This symlinks .jars to their shasums in a directory
# that git-fat can use as a source store.
#
class archiva::gitfat {
    Class['::archiva'] -> Class['::archiva::gitfat']
    
    $archiva_repository_path = '/var/lib/archiva/repositories'
    $gitfat_path             = '/var/lib/git-fat'
    $gitfat_archiva_path     = "${gitfat_path}/archiva"

    if !defined(File[$gitfat_path]) {
        file { $gitfat_path:
            ensure => 'directory',
        }
    }
    file { $gitfat_archiva_path:
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
        command => "/usr/local/bin/archiva-gitfat-link ${archiva_repository_path} ${gitfat_archiva_path} > /dev/null",
        minute  => '*/5',
        require => File['/usr/local/bin/archiva-gitfat-link'],
    }
}