# gridengine/join.pp

define gridengine::join(
    $sourcedir,
    $list  = undef,
) {

    if $list {
        file { "${sourcedir}/${::fqdn}":
            ensure  => file,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => inline_template("<% @list.each do |g| -%><%= g %>\n<% end -%>"),
        }
    } else {
        file { "${sourcedir}/${::fqdn}":
            ensure  => absent,
        }
    }
}
