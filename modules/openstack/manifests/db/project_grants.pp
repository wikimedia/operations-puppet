define openstack::db::project_grants(
    $db_user,
    $db_pass,
    $db_name,
    Array[Stdlib::Fqdn] $access_hosts,
    $privs = 'ALL PRIVILEGES',
    $project_name = undef,
) {
    $etc_dir = $project_name ? {
        undef   => $title,
        default => $project_name,
    }

    $ips = $access_hosts.map |Stdlib::Fqdn $fqdn| {
        dnsquery::lookup($fqdn)
    }.flatten.sort

    file { "/etc/${etc_dir}/${title}_grants.mysql":
        content   => template('openstack/db/grants.mysql.erb'),
        owner     => 'root',
        group     => 'root',
        mode      => '0644',
        show_diff => false,
    }
}
