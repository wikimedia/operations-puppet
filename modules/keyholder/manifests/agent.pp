# == keyholder::agent
#
# Resource for creating keyholder agents on a node
#
# === Parameters
#
# [*name*]
#   Used for service names, socket names, and default key name
#
#   should be shared. It is the caller's responsibility to ensure
#   the group exists. An array of group identifiers can also be provided
#   to allow access by multiple groups.
#
# [*trusted_groups*]
#   An array of group names or GIDs of the trusted user groups with which the
#   agent should be shared. It is the caller's responsibility to ensure
#   the groups exist.
#
# === Examples
#
#  keyholder::agent { 'mwdeploy':
#      trusted_groups   => ['wikidev', 'mwdeploy'],
#  }
#
define keyholder::agent(
    $trusted_groups = ['ops'],
    $ensure = 'present',
    $key_name = $name,
) {
    validate_ensure($ensure)

    require ::keyholder
    require ::keyholder::monitoring

    # Always add ops in the mix
    if !('ops' in $trusted_groups) {
        $real_trusted_groups = concat($trusted_groups, 'ops')
    } else {
        $real_trusted_groups = $trusted_groups
    }


    $key_name_safe = regsubst($key_name, '\W', '_', 'G')
    $key_content = secret("keyholder/${key_name_safe}")

    file { "/etc/keyholder.d/${key_name_safe}":
        ensure  => $ensure,
        content => $key_content,
        owner   => 'root',
        group   => 'keyholder',
        mode    => '0440',
    }

    file { "/etc/keyholder-auth.d/${key_name_safe}.yml":
        ensure  => $ensure,
        content => inline_template("---\n<%= [*@real_trusted_groups].map { |g| \"#{g}: [#{@key_name_safe}]\" }.join(\"\\n\") %>\n"),
        owner   => 'root',
        group   => 'keyholder',
        mode    => '0440',
    }
}
