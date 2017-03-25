class role::url_downloader {

    system::role { 'url_downloader': description => 'Upload-by-URL proxy' }

    include ::standard
    include ::profile::url_downloader

}
