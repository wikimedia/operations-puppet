# == keyholder::agent
#
# Resource for creating keyholder agents on a node
#
# Most instances of this resource are created from hiera, see scap::server
# and scap/server.yaml
#
# === Parameters
#
# [*name*]
#   This is the name of the ssh key managed by this agent. The key comes from
#   a call to secret which translates to:
#   puppet/private/modules/secret/secrets/keyholder/${name}[.pub]
#
# [*ensure*]
#   Defaults to 'present', this is passed directly to the file resources
#   that this resource manages.
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

    file { "/etc/keyholder.d/${key_name_safe}":
        ensure  => $ensure,
        content => secret("keyholder/${key_name_safe}"),
        owner   => 'root',
        group   => 'keyholder',
        mode    => '0440',
    }

    file { "/etc/keyholder.d/${key_name_safe}.pub":
        ensure  => $ensure,
        content => secret("keyholder/${key_name_safe}.pub"),
        owner   => 'root',
        group   => 'keyholder',
        mode    => '0440',
    }

    # generate the mapping between groups and keys. Used by ssh-agent-proxy
    file { "/etc/keyholder-auth.d/${key_name_safe}.yml":
        ensure  => $ensure,
        content => inline_template("---\n<%= [*@real_trusted_groups].map { |g| \"#{g}: [#{@key_name_safe}]\" }.join(\"\\n\") %>\n"),
        owner   => 'root',
        group   => 'keyholder',
        mode    => '0440',
    }
}
