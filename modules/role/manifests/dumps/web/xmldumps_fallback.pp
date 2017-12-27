# fallback web server of xml/sql dumps and other datasets
# also permits rsync from public mirrors and certain internal hosts
# lastly, serves thse files via nfs to certain internal hosts
class role::dumps::web::xmldumps_fallback {
    include ::standard
    include ::profile::base::firewall
    include ::profile::dumps::web::xmldumps_common
    include ::profile::dumps::rsyncer_peer

    system::role { 'role::dumps::web::xmldumps': description => 'fallback web, nfs and rsync server of xml/sql dumps' }
}
