class mailman::cron {

    # delete un-moderated held messages after 90 days (T109838)
    cron { 'delete_held_messages':
        ensure  => 'present',
        command => "/usr/bin/find /var/lib/mailman/data/ -name 'heldmsg-*' -type f -mtime +90 -exec rm {} \\; > /dev/null 2>&1",
        user    => 'root',
        hour    => '3',
        minute  => '0',
    }
}

