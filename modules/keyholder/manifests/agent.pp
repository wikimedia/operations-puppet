# == keyholder::agent
#
# Resource for creating keyholder agents on a node
#
# === Parameters
#
# [*name*]
#   Used for service names, socket names, and default key name
#
# [*trusted_group*]
#   The name or GID of the trusted user group with which the agent
#   should be shared. It is the caller's responsibility to ensure
#   the group exists. An array of group identifiers can also be provided
#   to allow access by multiple groups.
#
# [*ensure*]
#   If 'present', config will be enabled; if 'absent', disabled.
#   The default is 'present'.
#
# === Examples
#
#  keyholder::agent { 'mwdeploy':
#      trusted_group   => ['wikidev', 'mwdeploy'],
#  }
#
define keyholder::agent(
    $trusted_group,
    $ensure = 'present',
    $key_name = $title
) {
    validate_ensure($ensure)

    require ::keyholder
    require ::keyholder::monitoring

    $key_name_safe = regsubst($key_name, '\W', '_', 'G')
    $key_content = keyholder_key($key_name_safe, true)
    $fingerprint = join(['"', keyholder_fingerprint($key_name_safe), '"'])

    file { "/etc/keyholder.d/${key_name_safe}":
        ensure  => $ensure,
        content => $key_content,
        owner   => 'root',
        group   => 'keyholder',
        mode    => '0440',
    }

    file { "/etc/keyholder-auth.d/${key_name_safe}.yml":
        ensure  => $ensure,
        content => inline_template("---\n<%= [*@trusted_group].map { |g| \"#{g}: [#{@fingerprint}]\" }.join(\"\\n\") %>\n"),
        owner   => 'root',
        group   => 'keyholder',
        mode    => '0440',
    }
}
