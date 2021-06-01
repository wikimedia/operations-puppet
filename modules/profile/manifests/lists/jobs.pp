# periodic jobs running on a list server
class profile::lists::jobs(
    Integer $held_messages_age = lookup('profile::lists::jobs', {'default_value' => 90}),
    Array[String] $exclude_backups_list = lookup('mailman2_exclude_backups'),
){
    systemd::timer::job { 'delete_held_messages':
        ensure      => absent,
        user        => 'root',
        description => "delete un-moderated held messages after ${held_messages_age} days (T109838)",
        command     => "/usr/bin/find /var/lib/mailman/data/ -name 'heldmsg-*' -type f -mtime +${held_messages_age} -exec rm {} \\;",
        interval    => {'start' => 'OnCalendar', 'interval' => 'daily'},
    }

    systemd::timer::job { 'purge_attachments':
        ensure      => absent,
        user        => 'root',
        description => 'Purge attachments from lists with archiving disabled',
        command     => '/usr/local/sbin/purge_attachments',
        interval    => {'start' => 'OnCalendar', 'interval' => 'daily'},
    }

    file { '/etc/exclude_backups_list.json':
        ensure  => absent,
        owner   => 'root',
        group   => 'root',
        mode    => '0444',
        content => ordered_json($exclude_backups_list),
    }

    systemd::timer::job { 'check_exclude_backups':
        ensure      => absent,
        user        => 'root',
        description => 'Check exclude_backups list is up to date',
        command     => '/usr/local/sbin/check_exclude_backups',
        interval    => {'start' => 'OnCalendar', 'interval' => 'daily'},
        # Notify root@ when it fails
        send_mail   => true,
        require     => File['/etc/exclude_backups_list.json'],
    }
}
