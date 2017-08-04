class openstack2::keystone::cleanup (
    $active,
    $db_user,
    $db_pass,
    $db_host,
    $db_name,
    ) {

    # Cron doesn't take a bool
    if $active {
        $ensure = 'present'
    }
    else {
        $ensure = 'absent'
    }

    # Clean up expired keystone tokens, because otherwise keystone leaves them
    #  around forever.
    cron {
        'cleanup_expired_keystone_tokens':
            ensure  => $ensure,
            user    => 'root',
            minute  => 20,
            command => '/usr/bin/keystone-manage token_flush > /dev/null 2>&1',
        }

        # Clean up service user tokens.  These tend to pile up
        #  quickly, and are never used for Horizon sessions.
        #  so, don't wait for them to expire, just delete them
        #  after a few hours.
        #
        # Tokens only know when they expire and not when they
        #  were created.  Since token lifespan is 7.1
        #  days (613440 seconds), any token that expires
        #  less than 7 days from now is already at least
        #  2 hours old.
        cron {
            'cleanup_novaobserver_keystone_tokens':
                ensure  => $ensure,
                user    => 'root',
                minute  => 30,
                command => "/usr/bin/mysql ${db_name} -h${db_host} -u${db_user} -p${db_pass} -e 'DELETE FROM token WHERE user_id=\"novaobserver\" AND NOW() + INTERVAL 7 day > expires LIMIT 10000;'",
        }

        cron {
            'cleanup_novaadmin_keystone_tokens':
                ensure  => $ensure,
                user    => 'root',
                minute  => 40,
                command => "/usr/bin/mysql ${db_name} -h${db_host} -u${db_user} -p${db_pass} -e 'DELETE FROM token WHERE user_id=\"novaadmin\" AND NOW() + INTERVAL 7 day > expires LIMIT 10000;'",
        }
}
