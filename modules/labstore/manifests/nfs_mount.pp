# Manage NFS mounts
#
# This module is somewhat backwards from existing
# practice concerning application.
#
# We use defined() instead of hiera to apply
# resources associated with the mounts in one place.
#
# [*mount_path]
#  path on disk to mount share
#
# [*mount_name]
#  The unique identifier of this mount ('home', 'project', 'scratch', etc)
#
# [*share_path]
#  share path (use showmount -e $server to see possible)
#
# [*server]
#  NFS server address
#
# [*options]
#  Array of options to combine with the standard options
#
# [*block_timeout]
#  timeout to block for share availability

define labstore::nfs_mount(
    Stdlib::Unixpath           $mount_path,
    String                     $mount_name,
    Wmflib::Ensure             $ensure        = 'present',
    Array                      $options       = [],
    Integer                    $block_timeout = 180,
    Pattern[/^4(:?\.[0-2])?$/] $nfs_version   = '4',
    Optional[Stdlib::Host]     $server        = undef,
    Optional[Stdlib::Unixpath] $share_path    = undef,
){

    ensure_packages(['nfs-common'])

    include labstore::traffic_shaping

    $set_opts = ["vers=${nfs_version}",
                'bg',
                'intr',
                'sec=sys',
                'proto=tcp',
                'noatime',
                'lookupcache=all',
                'nofsc',
        ]

    $final_options = flatten([$set_opts,$options])

    if !defined(File['/data']) {
        file { '/data':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }

    if !defined(File['/mnt/nfs']) {
        file { '/mnt/nfs':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }

    if !defined(File['/public']) {
        file { '/public':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }

    if !defined(File['/usr/local/sbin/nfs-mount-manager']) {
        file { '/usr/local/sbin/nfs-mount-manager':
            ensure => present,
            owner  => 'root',
            group  => 'root',
            mode   => '0655',
            source => 'puppet:///modules/labstore/nfs-mount-manager',
        }
    }

    if ($ensure == 'absent') {

        exec { "cleanup-${mount_path}":
            command   => "/usr/local/sbin/nfs-mount-manager umount ${mount_path}",
            onlyif    => "/usr/local/sbin/nfs-mount-manager check ${mount_path}",
            logoutput => true,
            require   => File['/usr/local/sbin/nfs-mount-manager'],
        }

        mount { $mount_path:
            ensure  => absent,
            require => Exec["cleanup-${mount_path}"],
            notify  => Exec["remove-${mount_path}"],
        }

        exec { "remove-${mount_path}":
            command     => "/usr/bin/timeout -k 5s 10s /bin/rm -rf ${mount_path}",
            refreshonly => true,
            logoutput   => true,
        }
    }

    if ($ensure == 'present') {

        # 'present' is meant to manage only the status of entries in /etc/fstab
        # a notable exception to this is in the case of an entry managed as 'present'
        # puppet will attempt to remount that entry when options change /but/ only
        # if it is already mounted by forces outside of puppet.
        #
        # remount in general with NFS mounts is suspect as remount does not apply to
        # NFS specific configuration options and will fail on first run and then
        # be ignored until reboot where actual application occurs
        #
        # It is best practice to plan on a reboot in case of option changs or to
        # shuffle the NFS share access point via sym link and a new mount
        mount { $mount_path:
            ensure   => present,
            atboot   => true,
            fstype   => 'nfs',
            options  => join($final_options,','),
            device   => "${server}:${share_path}",
            require  => [File['/usr/local/sbin/nfs-mount-manager'], Package['nfs-common']],
            remounts => false,
        }

        # Via exec to gracefully handle the frozen mount case where
        # Puppet will normally get stuck and freeze raising load and effectively
        # failing to run
        exec { "create-${mount_path}":
            command   => "/usr/bin/timeout -k 5s 20s /bin/mkdir -p ${mount_path}",
            unless    => "/usr/bin/timeout -k 5s 60s /usr/bin/test -d ${mount_path}",
            logoutput => true,
            require   => Mount[$mount_path],
        }

        exec { "ensure-nfs-${name}":
            command   => "/usr/local/sbin/nfs-mount-manager mount ${mount_path}",
            unless    => "/usr/local/sbin/nfs-mount-manager check ${mount_path}",
            logoutput => true,
            require   => Exec["create-${mount_path}"],
        }
    }

    if !defined(File['/etc/modprobe.d/nfs-no-idmap.conf']) {
        # While the default on kernels >= 3.3 is to have idmap disabled,
        # doing so explicitly does no harm and ensures it is everywhere.
        file { '/etc/modprobe.d/nfs-no-idmap.conf':
            ensure  => present,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => "options nfs nfs4_disable_idmapping=1\n",
        }
    }
}
