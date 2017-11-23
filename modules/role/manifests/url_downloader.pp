# filtertags: labs-project-deployment-prep
class role::url_downloader {

    system::role { 'url_downloader': description => 'Upload-by-URL proxy' }

    include ::standard
    include ::profile::base::firewall
    include ::profile::url_downloader
}
