# /etc/cron.d/php5: crontab fragment for php5
#  This purges session files in session.save_path older than X,
#  where X is defined in seconds as the largest value of
#  session.gc_maxlifetime from all your SAPI php.ini files
#  or 24 minutes if not defined.  The script triggers only
#  when session.save_handler=files.
#
#  WARNING: The scripts tries hard to honour all relevant
#  session PHP options, but if you do something unusual
#  you have to disable this script and take care of your
#  sessions yourself.
#
# This file is managed by Puppet (modules/toollabs/files/php5.cron.d)
# Source: http://anonscm.debian.org/cgit/pkg-php/php.git/commit/debian/php5-common.php5.cron.d?id=4eb6c8234dd6085e3c96a5ebca86b1d70ac481e3

# Look for and purge old sessions every 30 minutes
09,39 *     * * *     root   [ -x /usr/lib/php5/sessionclean ] && /usr/lib/php5/sessionclean
