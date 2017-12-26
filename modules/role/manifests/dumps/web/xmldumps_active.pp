# active web server of xml/sql dumps and other datasets
# also permits rsync from public mirrors and certain internal hosts
# lastly, serves thse files via nfs to certain internal hosts
class role::dumps::web::xmldumps_active {
    include ::standard
    include ::profile::base::firewall
    include ::profile::dumps::web::xmldumps_active
    include ::profile::dumps::web::rsync_server
    include ::profile::dumps::web::dumpstatusfiles_sync
    include ::profile::dumps::rsyncer
    include ::profile::dumps::fetcher
    include ::profile::dumps::nfs
    include ::profile::dumps::web::cleanup
    include ::profile::dumps::web::cleanup_miscdatasets

    system::role { 'role::dumps::web::xmldumps': description => 'active web, nfs and rsync server of xml/sql dumps' }
}
