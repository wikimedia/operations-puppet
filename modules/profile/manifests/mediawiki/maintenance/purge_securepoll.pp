class profile::mediawiki::maintenance::purge_securepoll {
    profile::mediawiki::periodic_job { 'purge_securepollvotedata':
        command  => '/usr/local/bin/foreachwiki extensions/SecurePoll/cli/purgePrivateVoteData.php',
        interval => '01:00'
    }
}
