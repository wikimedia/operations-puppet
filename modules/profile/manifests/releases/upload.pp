class profile::releases::upload(
    $active_server = lookup('releases_server'),
){
    class { '::releases::reprepro::upload':
        upload_host => $active_server,
    }
}
