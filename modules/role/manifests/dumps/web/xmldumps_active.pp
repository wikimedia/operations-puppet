# active web server of xml/sql dumps and other datasets
# also permits rsync from public mirrors and certain internal hosts
# lastly, serves thse files via nfs to certain internal hosts
class role::dumps::web::xmldumps_active {
    include ::standard
    include ::profile::base::firewall
    include ::profile::dumps::web::xmldumps_common
    include ::profile::dumps::web::xmldumps_active
    include ::profile::dumps::distribution::rsync
    include ::profile::dumps::distribution::datasets::rsync_config
    include ::profile::dumps::distribution::mirrors::rsync_config
    include ::profile::dumps::distribution::datasets::fetcher
    include ::profile::dumps::distribution::datasets::dumpstatusfiles_sync

    system::role { 'role::dumps::web::xmldumps': description => 'active web, nfs and rsync server of xml/sql dumps' }
}
