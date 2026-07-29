class role::url_downloader {
    include profile::base::production
    include profile::firewall
    include profile::url_downloader
    include profile::lvs::realserver
    include profile::lvs::realserver::ipip
}
