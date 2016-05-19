# Manage NFS mounts

# This module is somewhat backwards from existing
# practice concerning application.  It relies on mount_nfs_volume.rb
# which whitelists hosts and mounts defined explicitly
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
    $project,
    $mount_path,
    $share_path,
    $server,
    $options = [],
    $block=false,
    $block_timeout = 180,
)
    {

    include labstore::traffic_shaping

    $set_opts = ['vers=4',
                'bg',
                'intr',
                'sec=sys',
                'proto=tcp',
                'port=0',
                'noatime',
                'lookupcache=none',
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

    if !defined(File['/public']) {
        file { '/public':
            ensure => directory,
            owner  => 'root',
            group  => 'root',
            mode   => '0755',
        }
    }

    if mount_nfs_volume($project, $name) {

        file { $mount_path:
            ensure  => directory,
        }

        if $block {
            if !defined(File['/usr/local/sbin/block-for-export']) {
                # This script will block until the NFS volume is available
                file { '/usr/local/sbin/block-for-export':
                    ensure => present,
                    owner  => root,
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

        mount { $mount_path:
            ensure  => mounted,
            atboot  => true,
            fstype  => 'nfs',
            options => join($final_options,','),
            device  => "${server}:${share_path}",
            require => File[$mount_path, '/etc/modprobe.d/nfs-no-idmap.conf'],
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
