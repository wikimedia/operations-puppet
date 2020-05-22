function conftool::cluster_credentials(
    String $def_user,
    String $def_pw,
    String $seed,
    Optional[String] $conftool_cluster
) >> Struct[{'username' => String, 'password' => String}] {
    if $conftool_cluster == undef {
        {'username' => $def_user, 'password' => $def_pw}
    } else {
        {'username' => "pool-${::site}-${conftool_cluster}", 'password' => wmflib::autogen_password("${::site}-${conftool_cluster}", $seed)}
    }
}
