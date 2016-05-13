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
# [*trusted_group*]
#   The name or GID of the trusted user group with which the agent
#   should be shared. It is the caller's responsibility to ensure
#   the group exists. An array of group identifiers can also be provided
#   to allow access by multiple groups.
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
    $trusted_group = [],
    $key_file = "${name}_rsa",
    $key_content = undef,
    $key_secret = undef,
) {
    require ::keyholder
    require ::keyholder::monitoring

    # Always add ops in the mix
    if ! is_array($trusted_group) {
        fail('trusted_group parameter should be an array')
    }
    if empty($trusted_group) {
        $real_trusted_groups = ['ops']
    } else {
        $real_trusted_groups = concat($trusted_group, 'ops')
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
