class mediawiki::maintenance::purge_securepoll( $ensure = present ) {
    cron { 'purge_securepollvotedata':
        ensure  => $ensure,
        user    => $::mediawiki::users::web,
        hour    => 1,
        minute  => 0,
        command => '/usr/local/bin/foreachwiki extensions/SecurePoll/cli/purgePrivateVoteData.php >/dev/null 2>&1',
    }
}
