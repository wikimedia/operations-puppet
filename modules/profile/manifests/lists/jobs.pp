# periodic jobs running on a list server
class profile::lists::jobs(
    Integer $held_messages_age = lookup('profile::lists::jobs', {'default_value' => 90}),
){
    systemd::timer::job { 'delete_held_messages':
        ensure      => 'present',
        user        => 'root',
        description => "delete un-moderated held messages after ${held_messages_age} days (T109838)",
        command     => "/usr/bin/find /var/lib/mailman/data/ -name 'heldmsg-*' -type f -mtime +${held_messages_age} -exec rm {} \\;",
        interval    => {'start' => 'OnCalendar', 'interval' => 'daily'},
    }

    systemd::timer::job { 'purge_attachments':
        ensure      => 'present',
        user        => 'root',
        description => 'Purge attachments from lists with archiving disabled',
        command     => '/usr/local/sbin/purge_attachments',
        interval    => {'start' => 'OnCalendar', 'interval' => 'daily'},
    }

}
