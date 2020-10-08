class pontoon::enc (
  String $stack,
) {
    require_package(['python3-yaml'])

    file { '/etc/pontoon-stack':
        ensure  => 'present',
        replace => 'no', # Write the file once if absent, don't change it afterwards
        content => $stack,
        mode    => '0444',
    }

    file { '/etc/pontoon-enc.yaml':
        ensure => 'link',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        target => "/var/lib/git/operations/puppet/modules/pontoon/files/${stack}/rolemap.yaml",
    }

    $stack_hiera = "/var/lib/git/operations/puppet/modules/pontoon/files/${stack}/hiera/"
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
