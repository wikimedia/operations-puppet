define openstack::db::project_grants(
    $db_user,
    $db_pass,
    $db_name,
    $db_host,
    $access_hosts,
    $project_name = undef,
) {
    $etc_dir = $project_name ? {
        undef   => $title,
        default => $project_name,
    }

    file { "/etc/${etc_dir}/${title}_grants.mysl":
        content   => template('openstack/db/grants.mysql.erb'),
        owner     => 'root',
        group     => 'root',
        mode      => '0644',
        show_diff => false,
    }
}
