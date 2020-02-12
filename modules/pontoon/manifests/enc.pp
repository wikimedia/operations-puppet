class pontoon::enc (
  String $stack,
) {
    require_package(['python3-yaml'])

    file { '/etc/pontoon-enc.yaml':
        ensure => 'link',
        owner  => 'root',
        group  => 'root',
        mode   => '0444',
        target => "/var/lib/git/operations/puppet/modules/pontoon/files/${stack}",
    }

    file { '/usr/local/bin/puppet-enc':
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
        source => 'puppet:///modules/pontoon/enc.py',
    }
}
