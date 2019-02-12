# == openstack::keystone::cleanup ==
#
# Enables periodic jobs that will delete various classes of Keystone tokens 
#
# === Parameters ===
# [*active*]
#   If these definitions should be present or absent
# [*db_user*]
#   Username to access the Keystone database
# [*db_pass*]
#   Password to access the Keystone database
# [*db_host*]
#   Server hosting Keystone database
# [*db_name*]
#   Keystone database name
#
class openstack::keystone::cleanup (
    Boolean $active,
    String  $db_user,
    String  $db_pass,
    String  $db_host,
    String  $db_name,
) {

    # systemd::timer::job does not take a boolean    
    if $active {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    # TODO: Remove after change is applied
    cron { 'cleanup_expired_keystone_tokens':
        ensure => absent,
        user   => 'root'
    }

    # Keystone does not remove expired tokens by default
    systemd::timer::job { 'keystone_delete_expired_tokens':
        ensure                    => $ensure,
        description               => 'Delete expired Keystone tokens',
        command                   => '/usr/bin/keystone-manage token_flush > /dev/null 2>&1',
        interval                  => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:20:00', # Every hour at minute 20
        },
        logging_enabled           => false,
        monitoring_enabled        => true,
        monitoring_contact_groups => 'wmcs-team',
        user                      => 'root',
    }

    # Delete service tokens that expire in less than 7 days.
    #
    # Rationale: Tokens do not know when they were created, only when they 
    # expire. Since the token lifespan is 7.1 days (613440sec), any token
    # that expires in less than 7 days from now is already at least 2 hours
    # old.
    #
    # These are not used for user sessions in Horizon.

    # TODO: Remove after change is applied
    cron { 'cleanup_novaobserver_keystone_tokens':
        ensure => absent,
        user   => 'root',
    }

    $keystone_db_credentials = '/etc/keystone/keystone.my.cnf'
    $delete_novaobserver_tokens_cmd = "/usr/bin/mysql --defaults-file=${keystone_db_credentials} ${db_name} -h${db_host} -e 'DELETE FROM token WHERE user_id=\"novaobserver\" AND NOW() + INTERVAL 7 day > expires ORDER BY id LIMIT 10000;'"

    systemd::timer::job { 'keystone_novaobserver_delete_tokens':
        ensure                    => $ensure,
        description               => 'Delete old Keystone tokens for novaobserver user',
        command                   => $delete_novaobserver_tokens_cmd,
        interval                  => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:30:00', # Every hour at minute 30
        },
        logging_enabled           => false,
        monitoring_enabled        => true,
        monitoring_contact_groups => 'wmcs-team',
        user                      => 'root',
    }

    # TODO: Remove after change is applied
    cron { 'cleanup_novaadmin_keystone_tokens':
        ensure => absent,
        user   => 'root',
    }

    $delete_novaadmin_tokens_cmd = "/usr/bin/mysql --defaults-file=${keystone_db_credentials} ${db_name} -h${db_host} -e 'DELETE FROM token WHERE user_id=\"novaadmin\" AND NOW() + INTERVAL 7 day > expires ORDER BY id LIMIT 10000;'"

    systemd::timer::job { 'keystone_novaadmin_delete_tokens':
        ensure                    => $ensure,
        description               => 'Delete old Keystone tokens for novaadmin user',
        command                   => $delete_novaadmin_tokens_cmd,
        interval                  => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:40:00', # Every hour at minute 40
        },
        logging_enabled           => false,
        monitoring_enabled        => true,
        monitoring_contact_groups => 'wmcs-team',
        user                      => 'root',
    }
}
