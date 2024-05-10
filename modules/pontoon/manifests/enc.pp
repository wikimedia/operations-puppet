# SPDX-License-Identifier: Apache-2.0
class pontoon::enc {
    ensure_packages(['python3-ruamel.yaml', 'python3-pip'])

    # The ENC 'interface' is the 'pontoon-enc' script, it is installed in /usr/local/bin and
    # doubles as an utility to interact with the current stack (e.g. --list-hosts)
    # Similarly to Puppet code, pontoon-enc code runs "live" from the puppet.git checkout

    # /etc/pontoon/stack is the entry point for Pontoon to know which stack we're in.
    # The bootstrap process will set the value of this file to 'bootstrap'.

    # The stack name is not set in hiera to:
    # * avoid circular dependencies for the ENC
    # * not have to have it in git, and thus need to carry a patch on top of 'production'
    #   to set the value
    $configured_stack = file('/etc/pontoon/stack')[0, -2]
    $pontoon_home = '/srv/git/operations/puppet/modules/pontoon/files'
    $stack_hiera = "${pontoon_home}/${configured_stack}/hiera/"
    file { '/etc/pontoon/hiera/stack':
        # The directory might not exist but that's ok, it might eventually
        ensure => 'link',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        target => $stack_hiera,
    }

    exec { 'Install Pontoon ENC':
        creates => '/usr/local/bin/pontoon-enc',
        command => '/usr/bin/pip install --no-deps --break-system-packages --editable .',
        cwd     => $pontoon_home,
        require => [Package['python3-pip'], Git::Clone['operations/puppet']],
    }
}
