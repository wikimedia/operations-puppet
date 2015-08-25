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
#   the group exists.
#
# [*key_fingerprint*]
#   Fingerprint of the public half of the private keyfile specified
#   by $key_file
#
# === Examples
#
#  keyholder::agent { 'mwdeploy':
#      keyfile         => 'mwdeploy_key_rsa',
#      trusted_group   => 'wikidev',
#      key_fingerprint => '00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00'
#      require         => Group['wikidev'],
#  }
#
define keyholder::agent(
    $trusted_group,
    $key_fingerprint,
    $key_file = "${name}_rsa",
) {
    file { "/etc/keyholder-auth.d/${name}.yml":
        content => inline_template("---\n<%= @trusted_group %>: ['<%= @key_fingerprint %>']\n"),
        owner   => 'root',
        group   => 'keyholder',
        mode    => '0440',
    }

    # lint:ignore:puppet_url_without_modules
    keyholder::private_key { $key_file:
        source  => "puppet:///private/ssh/tin/${key_file}",
    }
    # lint:endignore
}
