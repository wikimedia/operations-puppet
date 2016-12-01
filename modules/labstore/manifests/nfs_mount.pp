# Manage NFS mounts
#
# This module is somewhat backwards from existing
# practice concerning application.  It relies on mount_nfs_volume.rb
# which whitelists hosts and mounts via yaml defined explicitly
# by project. This same yaml file is used server side to determine
# share setup in exports.d.
#
# Because of this we use defined() instead of hiera to apply
# resources associated with the mounts in one place.
#
# [*project]
#  project name to determine eligibility via mount_nfs_volume.rb
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
# [*block]
#  boolean to determine if we should block to wait for share
#
# [*block_timeout]
#  timeout to block for share availability

define labstore::nfs_mount(
    $mount_path,
    $mount_name,
    $ensure = 'present',
    $project = undef,
    $share_path = undef,
    $server = undef,
    $options = [],
    $block=false,
    $block_timeout = 180,
    $lookupcache='none',
)
    {

    include ::labstore::traffic_shaping

    $set_opts = ['vers=4',
                'bg',
                'intr',
                'sec=sys',
                'proto=tcp',
                'port=0',
                'noatime',
                "lookupcache=${lookupcache}",
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

    # 8/23/2016 cleanup can be removed after a week
    if !defined(File['/usr/local/sbin/nfs-mount-manager.sh']) {
        file { '/usr/local/sbin/nfs-mount-manager.sh':
            ensure => absent,
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

    if ($ensure == 'absent') and mount_nfs_volume($project, $mount_name) {

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

    if ($ensure == 'present') and mount_nfs_volume($project, $mount_name) {

        if $block {
            if !defined(File['/usr/local/sbin/block-for-export']) {
                # This script will block until the NFS volume is available
                file { '/usr/local/sbin/block-for-export':
                    ensure => present,
                    owner  => 'root',
                    group  => 'root',
                    mode   => '0555',
                    source => 'puppet:///modules/labstore/block-for-export',
                }
            }
            exec { "block-for-nfs-${name}":
                command => "/usr/local/sbin/block-for-export ${server} project/${project} ${block_timeout}",
                require => [File['/etc/modprobe.d/nfs-no-idmap.conf'], File['/usr/local/sbin/block-for-export']],
                unless  => "/bin/mountpoint -q ${mount_path}",
            }
        }

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
            require  => File['/usr/local/sbin/nfs-mount-manager'],
            remounts => false,
        }

        # Via exec to gracefully handle the frozen mount case where
        # Puppet will normally get stuck and freeze raising load and effectively
        # failing to run
        exec { "create-${mount_path}":
            command => "/usr/bin/timeout -k 5s 10s /bin/mkdir ${mount_path}",
            unless  => "/usr/bin/timeout -k 5s 10s /usr/bin/test -d ${mount_path}",
            require => Mount[$mount_path],
        }

        exec { "ensure-nfs-${name}":
            command   => "/usr/local/sbin/nfs-mount-manager mount ${mount_path}",
            unless    => "/usr/local/sbin/nfs-mount-manager check ${mount_path}",
            require   => Exec["create-${mount_path}"],
            logoutput => true,
        }

        if !defined(Diamond::Collector['Nfsiostat']) {
            diamond::collector { 'Nfsiostat':
                source  => 'puppet:///modules/diamond/collector/nfsiostat.py',
                require => Package['diamond'],
            }
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

        file { '/etc/idmapd.conf':
            ensure => absent,
        }
    }
}
