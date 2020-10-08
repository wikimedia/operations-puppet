class pontoon::enc (
  String $stack,
) {
    require_package(['python3-yaml'])

    # Write the file once if absent, and don't change the file otherwise.
    # The idea is to protect against accidental changes of "$stack" after a Pontoon server has been
    # initialized.
    file { '/etc/pontoon-stack':
        ensure  => 'present',
        replace => 'no',
        content => $stack,
        mode    => '0444',
    }

    $configured_stack = file('/etc/pontoon-stack').strip('\n')

    $stack_hiera = "/var/lib/git/operations/puppet/modules/pontoon/files/${configured_stack}/hiera/"
    file { '/etc/puppet/hieradata/pontoon':
        ensure => find_file($stack_hiera) ? {
                        undef   => 'absent',
                        default => 'link',
                  },
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
