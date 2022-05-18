# If active, send the backups generated on /srv/backup to long term storage
# This class is similar to P::dbbackups:bacula, but differs in that
# it is specific for configuration of external store database (wiki content)
# backups
# Requires including ::profile::backup::host on the role that uses it
class profile::dbbackups::bacula_es (
    Boolean $active = lookup('profile::dbbackups::bacula_es::active'),
) {
    if $active {
        # Warning: because we do-cross dc backups, this can get confusing:
        if $::site == 'eqiad' {
            # backup hosts on eqiad store data on codfw (cross-dc)
            $jobdefaults_rw = 'Weekly-Thu-EsRwCodfw'
            $jobdefaults_ro = 'Weekly-Mon-EsRoCodfw'
        } elsif $::site == 'codfw' {
            # backups hosts on codfw store data on eqiad (cross-dc)
            $jobdefaults_rw = 'Weekly-Thu-EsRwEqiad'
            $jobdefaults_ro = 'Weekly-Mon-EsRoEqiad'
        } else {
            fail('Only eqiad or codfw pools are configured for content database backups.')
        }
        backup::set { 'mysql-srv-backups-dumps-latest':
            jobdefaults => $jobdefaults_rw,
        }
        # read only databases have normally backups disabled, and only are
        # enabled when one-time backups are taken, or every 5 years
        # JobIds for read only backups:
        # taken on eqiad, stored on codfw: { es1:334775 es2:336775 es3:338718}
        # taken on codfw, stored on eqiad: { es1:334776 es2:334788 es3:334903}
        # backup::set { 'mysql-srv-backups-dumps-latest':
        #     jobdefaults => $jobdefaults_ro,
        # }
    }
}
