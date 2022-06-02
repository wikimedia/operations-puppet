# SPDX-License-Identifier: Apache-2.0
class pontoon::enc {
    ensure_packages(['python3-yaml'])

    # /etc/pontoon-stack is the entry point for Pontoon to know which stack we're in.
    # The bootstrap process will set the value of this file to 'bootstrap'.

    # The value is not set in hiera to:
    # * avoid circular dependencies for the ENC
    # * not have to have it in git, and thus need to carry a patch on top of 'production'
    #   to set the value

    $configured_stack = file('/etc/pontoon-stack').strip('\n')

    $stack_hiera = "/var/lib/git/operations/puppet/modules/pontoon/files/${configured_stack}/hiera/"
    file { '/etc/puppet/hieradata/pontoon':
        # The directory might not exist but that's ok, it might eventually
        ensure => 'link',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        target => $stack_hiera,
    }

    file { '/usr/local/bin/puppet-enc':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/pontoon/enc.py',
    }
}
