# == keyholder::agent
#
# Resource for creating keyholder agents on a node
#
# === Parameters
#
# [*name*]
#   Used for service names, socket names, and default key name
#
# [*key_file*]
#   The name of the key file stored in puppet private
#   Should exist prior to running a defined resource
#
# [*trusted_groups*]
#   An array of group names or GIDs of the trusted user groups with which the agent
#   should be shared. It is the caller's responsibility to ensure
#   the groups exist.
#
# [*key_fingerprint*]
#   Fingerprint of the public half of the private keyfile specified
#   by $key_file
#
# === Examples
#
#  keyholder::agent { 'mwdeploy':
#      key_file         => 'mwdeploy_key_rsa',
#      trusted_group   => ['wikidev', 'mwdeploy'],
#      key_fingerprint => '00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00'
#      require         => Group['wikidev'],
#  }
#
define keyholder::agent(
    $key_fingerprint,
    $trusted_groups = ['ops'],
    $key_file = "${name}_rsa",
    $key_content = undef,
    $key_secret = undef,
) {
    require ::keyholder
    require ::keyholder::monitoring

    # Always add ops in the mix
    if !('ops' in $trusted_groups) {
        $real_trusted_groups = concat($trusted_groups, 'ops')
    } else {
        $real_trusted_groups = $trusted_groups
    }

    file { "/etc/keyholder-auth.d/${name}.yml":
        content => inline_template("---\n<% [*@real_trusted_groups].each do |g| %><%= g %>: ['<%= @key_fingerprint %>']\n<% end %>"),
        owner   => 'root',
        group   => 'keyholder',
        mode    => '0440',
    }

    # lint:ignore:puppet_url_without_modules
    if $key_content {
        keyholder::private_key { $key_file:
            content  => $key_content,
        }
    } elsif $key_secret {
        keyholder::private_key { $key_file:
            content => secret($key_secret)
        }
    } else {
        keyholder::private_key { $key_file:
            source  => "puppet:///private/ssh/tin/${key_file}",
        }
    }
    # lint:endignore
}
