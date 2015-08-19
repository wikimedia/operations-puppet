# helper scripts for mailman admins
class mailman::scripts {

    file { '/var/lib/mailman/bin/remove_from_private':
        ensure => 'present',
        owner  => 'root',
        group  => 'list',
        mode   => '0550',
        source => 'puppet:///modules/mailman/scripts/remove_from_private.sh'
    }

    file { '/var/lib/mailman/bin/import_list.sh':
        ensure => 'present',
        owner  => 'root',
        group  => 'list',
        mode   => '0550',
        source => 'puppet:///modules/mailman/scripts/import_list.sh'
    }

    file { '/var/lib/mailman/bin/import_all_lists.sh':
        ensure => 'present',
        owner  => 'root',
        group  => 'list',
        mode   => '0550',
        source => 'puppet:///modules/mailman/scripts/import_all_lists.sh'
    }
}
