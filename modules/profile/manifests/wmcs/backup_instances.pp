# SPDX-License-Identifier: Apache-2.0

class profile::wmcs::backup_instances(
    String               $backup_interval = lookup('profile::wmcs::backy2::instance_backup_time'),
    String               $ceph_vm_pool    = lookup('profile::cloudceph::client::rbd::pool'),
) {
    file { '/etc/wmcs_backup_instances.yaml':
        ensure  => 'present',
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('profile/wmcs/backy2/wmcs_backup_instances.yaml.erb');
    }

    systemd::timer::job { 'backup_vms':
        ensure                    => present,
        description               => 'Backup vms assigned to this host',
        command                   => '/usr/local/sbin/wmcs-backup instances backup-assigned-vms',
        interval                  => {
          'start'    => 'OnCalendar',
          'interval' => $backup_interval,
        },
        logging_enabled           => true,
        monitoring_enabled        => true,
        monitoring_contact_groups => 'wmcs-bots',
        monitoring_notes_url      => 'https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin/Runbooks/Check_unit_status_of_backup_vms',
        user                      => 'root',
    }

    systemd::timer::job { 'purge_vm_backup':
        ensure                    => present,
        description               => 'purge old VM backups; allow backy2 to decide what is too old',
        command                   => '/usr/local/sbin/wmcs-purge-backups',
        after                     => 'backup_vms.service',
        interval                  => {
          'start'    => 'OnCalendar',
          'interval' => '*-*-* 00:05:00', # daily at five past midnight
        },
        logging_enabled           => true,
        monitoring_enabled        => true,
        monitoring_contact_groups => '',
        user                      => 'root',
    }
}
