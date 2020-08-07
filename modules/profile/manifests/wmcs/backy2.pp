class profile::wmcs::backy2(
    String       $cluster_name = lookup('profile::wmcs::backy2::cluster_name'),
    Stdlib::Fqdn $db_host      = lookup('profile::wmcs::backy2::db_host'),
    String       $db_name      = lookup('profile::wmcs::backy2::db_name'),
    String       $db_user      = lookup('profile::wmcs::backy2::db_user'),
    String       $db_pass      = lookup('profile::wmcs::backy2::db_pass'),
) {
    class {'::backy2':
        cluster_name => $cluster_name,
        db_host      => $db_host,
        db_name      => $db_name,
        db_user      => $db_user,
        db_pass      => $db_pass,
    }
}
