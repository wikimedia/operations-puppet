# Class: profile::archiva
#
# Installs Apache Archiva and sets up a cron job to symlink .jar files to
# a git-fat store.
#
class profile::archiva(
    $enable_backup = hiera('profile::archiva::enable_backup', false),
) {
    require_package('default-jdk')

    # needed by ssl_ciphersuite() used in ::archiva::proxy
    class { '::sslcert::dhparam': }

    class { '::archiva': }

    class { '::archiva::gitfat': }

    # This uses modules/rsync to set up an rsync daemon service.
    # An empty address field will allow rsync to bind to IPv6/4
    # interfaces.
    class { '::rsync::server':
        address => '',
    }

    $archiva_path = $::archiva::gitfat::archiva_path

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
