# SPDX-License-Identifier: Apache-2.0
# === define: query_service::mount_dumps
#
# Mounts dumps over nfs for data reload purposes

class query_service::mount_dumps(
    Array[String] $servers,
    String $active_server,
) {
    ensure_packages(['nfs-common'])

    file {'/mnt/nfs':
        ensure => directory,
    }

    file { '/mnt/nfs/README':
        content => 'Please use /mnt/dumps to read from the active server',
    }

    file {'/mnt/dumps':
        ensure => 'link',
        target => "/mnt/dumps-${active_server}",
    }

    $servers.each |String $server| {
        file { "/mnt/nfs/dumps-${server}":
            ensure => 'directory',
            owner  => 'dumpsgen',
            group  => 'dumpsgen',
        }

        mount { "/mnt/nfs/dumps-${server}":
            ensure  => 'mounted',
            device  => "${server}:/",
            fstype  => 'nfs',
            options => 'ro,bg,tcp,rsize=8192,wsize=8192,timeo=14,intr',
            atboot  => true,
            require => File["/mnt/nfs/dumps-${server}"],
        }
    }
}
