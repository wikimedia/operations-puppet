# SPDX-License-Identifier: Apache-2.0
# Defines a custom Facter fact, $puppet_config_dir, which specifies the
# location of Puppet's configuration directory (usually /etc/puppet).
require 'puppet'

Facter.add('puppet_config_dir') do
    setcode do
        Puppet.settings[:confdir]
    end
end
