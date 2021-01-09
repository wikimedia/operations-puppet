class profile::mailman3 (
    String $host            = lookup('profile::mailman3::host'),
    String $db_host         = lookup('profile::mailman3::db_host'),
    String $db_password     = lookup('profile::mailman3::db_password'),
    String $db_password_web = lookup('profile::mailman3::web::db_password'),
    String $api_password    = lookup('profile::mailman3::api_password'),
    String $web_secret      = lookup('profile::mailman3::web::secret'),
    String $archiver_key    = lookup('profile::mailman3::archiver_key'),
) {
    class { '::mailman3':
        host            => $host,
        db_host         => $db_host,
        db_password     => $db_password,
        db_password_web => $db_password_web,
        api_password    => $api_password,
        archiver_key    => $archiver_key,
        web_secret      => $web_secret,
    }
}
