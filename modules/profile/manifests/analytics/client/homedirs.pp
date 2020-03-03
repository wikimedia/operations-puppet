# == Class profile::analytics::client::homedirs
#
# Ensure that all directories that may contain PII data
# have proper readability settings.
#
class profile::analytics::client::homedirs {

    # Automatically chmod/chown home directories of analytics-privatedata-group
    # to 750 / $user:analytics-privatedata-users.
    # This should ensure that PII data copied from Hadoop to the local file
    # system is not readable by users outside analytics-privatedata-group.

    file { '/usr/local/bin/ensure_private_homedir_permissions':
        mode   => '0750',
        owner  => 'root',
        group  => 'root',
        source => 'puppet:///modules/profile/analytics/client/homedirs/ensure_private_homedir_permissions',
    }

    systemd::timer::job { 'ensure_private_homedir_permissions':
        ensure                    => 'present',
        logging_enabled           => false,
        user                      => 'root',
        description               => 'Ensure correct chmod/chown permissions on home directories of groups with access to PII data.',
        command                   => '/usr/local/bin/ensure_private_homedir_permissions',
        interval                  => {
            'start'    => 'OnCalendar',
            'interval' => '*-*-* *:30:00', # hourly at half-past
        },
        monitoring_enabled        => true,
        monitoring_contact_groups => 'analytics',
        require                   => File[
            '/usr/local/bin/ensure_private_homedir_permissions',
        ],
    }
}
