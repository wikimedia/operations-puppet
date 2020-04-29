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
# [*priv_key_path*]
#   An optional path to a local SSH private key to use instead of calling
#   secret() to handle WMCS installations, where there isn't secret support on
#   a per-project basis. The name parameter must still be specified.
#   [optional, default: undef]
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
    $priv_key_path = undef,
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

    # Get the keys from secret() unless $priv_key_path is set
    $content_priv_key = $priv_key_path ? {
        undef => secret("keyholder/${key_name_safe}"),
        default => undef,
    }
    $content_pub_key = $priv_key_path ? {
        undef => secret("keyholder/${key_name_safe}.pub"),
        default => undef,
    }
    # Set the public key path if $priv_key_path is set
    $pub_key_path = $priv_key_path ? {
        undef => undef,
        default => "${priv_key_path}.pub",
    }

    file { "/etc/keyholder.d/${key_name_safe}":
        ensure    => $ensure,
        content   => $content_priv_key,  # undef if $priv_key_path is set
        source    => $priv_key_path,  # undef if $content_priv_key is set
        show_diff => false,
        owner     => 'root',
        group     => 'keyholder',
        mode      => '0440',
    }

    file { "/etc/keyholder.d/${key_name_safe}.pub":
        ensure    => $ensure,
        content   => $content_pub_key,  # undef if $source_pub_key is set
        source    => $pub_key_path,  # undef if $content_pub_key is set
        show_diff => false,
        owner     => 'root',
        group     => 'keyholder',
        mode      => '0444',
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
