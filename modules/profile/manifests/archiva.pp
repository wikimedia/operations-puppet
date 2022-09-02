# SPDX-License-Identifier: Apache-2.0
# Class: profile::archiva
#
# Installs Apache Archiva and sets up a systemd timer to symlink .jar files to a git-fat store.
#
class profile::archiva(
    $enable_backup  = lookup('profile::archiva::enable_backup', { 'default_value' => false }),
    $contact_groups = lookup('profile::archiva::contact_groups', { 'default_value' => 'analytics' }),
) {
    # needed by ssl_ciphersuite() used in ::archiva::proxy
    class { '::sslcert::dhparam': }

    class { '::archiva':
        user_database_base_dir => '/srv/archiva',
    }

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

    $link_command = "cd ${archiva_gitfat_path} && /usr/local/bin/archiva-gitfat-link ${archiva_repository_path} ."

    systemd::timer::job { 'archiva-gitfat-link':
        description               => 'Archiva tool to create jar symlinks using their sha1 checksum as filename.',
        command                   => "/bin/bash -c '${link_command}'",
        interval                  => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:00/5:00',
        },
        logfile_basedir           => '/var/log/archiva',
        logfile_name              => 'archiva-gitfat-link.log',
        syslog_identifier         => 'archiva-gitfat-link',
        user                      => 'archiva',
        monitoring_enabled        => true,
        monitoring_contact_groups => $contact_groups,
    }

    # This uses modules/rsync to set up an rsync daemon service.
    # An empty address field will allow rsync to bind to IPv6/4
    # interfaces.
    class { '::rsync::server':
        address => '',
    }

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

    # Bacula backups for /var/lib/archiva.
    if $enable_backup {
        include ::profile::backup::host
        backup::set { 'var-lib-archiva':
            require => Class['::archiva']
        }
    }

    # Archiva's rsync has no srange restrictions since git-fat uses rsync,
    # and it must be (read-only) reachable from everywhere. This is particularly
    # noticeable in set ups where Archiva is exposed to the public Internet,
    # since local set ups would not be able to pull dependencies if rsync
    # wasn't properly exposed.
    ferm::service { 'archiva_rsync':
        proto => 'tcp',
        port  => '873',
    }
}
