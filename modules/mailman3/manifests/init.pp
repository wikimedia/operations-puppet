class mailman3 (
    String $db_host,
    String $db_password,
    String $api_password,
    String $mailman3_service_ensure = 'running',
) {

    class { '::mailman3::listserve':
        mailman3_service_ensure => $mailman3_service_ensure,
        db_host                 => $db_host,
        db_password             => $db_password,
        api_password            => api_password
    }

}
