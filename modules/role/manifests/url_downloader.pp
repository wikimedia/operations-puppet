# filtertags: labs-project-deployment-prep
class role::url_downloader {

    system::role { 'url_downloader': description => 'Upload-by-URL proxy' }

    include ::profile::standard
    include ::profile::base::firewall
    include ::profile::base::firewall::log
    include ::profile::url_downloader
}
