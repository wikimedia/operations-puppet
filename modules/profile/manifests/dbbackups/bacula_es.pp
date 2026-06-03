# SPDX-License-Identifier: Apache-2.0
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
        # enabled when one-time backups are taken, or every 5 years, or
        # on recovery needed.
        # JobIds for read only backups:
        # taken on eqiad, stored on codfw:
        # (backup1013.eqiad.wmnet-Weekly-Mon-EsRoCodfw-mysql-srv-backups-dumps-latest):
        # { 'es1': 714994, 'es2': 716397, 'es3': 716619, 'es4': 716844, 'es5[WIP]': 717050,
        #   'es6-ro': 0, 'es7-ro': 0 }
        # taken on codfw, stored on eqiad
        # (backup2013.codfw.wmnet-Weekly-Mon-EsRoEqiad-mysql-srv-backups-dumps-latest):
        # { 'es1': 716404, 'es2': 716618, 'es3': 716649, 'es4': 716843, 'es5': 716878,
        #   'es6-ro': 717049, 'es7-ro[WIP]': 717069 }
        #backup::set { 'mysql-srv-backups-dumps-latest':
        #    jobdefaults => $jobdefaults_ro,
        #}
    }
}
