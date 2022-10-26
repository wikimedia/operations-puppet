# SPDX-License-Identifier: Apache-2.0
# sonofgridengine/join.pp

define sonofgridengine::join(
    $sourcedir,
    $list  = undef,
) {

    if $list {
        file { "${sourcedir}/${facts['hostname']}.${::wmcs_project}.eqiad1.wikimedia.cloud":
            ensure  => file,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => inline_template("<% @list.each do |g| -%><%= g %>\n<% end -%>"),
        }
    } else {
        file { "${sourcedir}/${facts['hostname']}.${::wmcs_project}.eqiad1.wikimedia.cloud":
            ensure  => absent,
        }
    }
}
