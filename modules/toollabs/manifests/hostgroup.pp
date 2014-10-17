# Class: toollabs::hostgroup
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class toollabs::hostgroup($groups = undef) {

    $hgstore  = "${toollabs::store}/hostgroup"

    file { $hgstore:
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
    }

    if $groups {
        file { "${hgstore}/${fqdn}":
            ensure  => file,
            owner   => 'root',
            group   => 'root',
            mode    => '0444',
            content => inline_template('<% @groups.each do |g| -%><%= g %><% end -%>'),
        }
    }

}
