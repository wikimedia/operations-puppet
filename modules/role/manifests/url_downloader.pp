class role::url_downloader {

    system::role { 'url_downloader': description => 'Upload-by-URL proxy' }

    include ::profile::base::production
    include ::profile::base::firewall
    include ::profile::url_downloader
}
