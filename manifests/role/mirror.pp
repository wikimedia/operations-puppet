# role/mirror.pp
# mirror::media and mirror::dumps role classes

class role::mirror::common {

    package { 'rsync':
        ensure => latest,
    }

    include vm::higher_min_free_kbytes
}

class role::mirror::media {
    include role::mirror::common

    system::role { 'role::mirror::media':
        description => 'Media mirror (rsync access for external mirrors)',
    }

    file { '/root/backups/rsync-media-cron.sh':
        ensure => present,
        mode   => '0755',
        source => 'puppet:///files/misc/mirror/rsync-media-cron.sh',
    }

    cron { 'media_rsync':
        ensure      => present,
        user        => 'root',
        minute      => '20',
        hour        => '3',
        command     => '/root/backups/rsync-media-cron.sh',
        environment => 'MAILTO=ops-dumps@wikimedia.org',
    }
}
