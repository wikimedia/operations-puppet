# == Class: phabricator::arcanist
#
# Installs the phabricator client, arcanist, from git.
# Clone the arcanist and libphutil repositories into /usr/local/share/, then
# link /usr/local/bin/arc to the arc executable
#
class phabricator::arcanist {
    git::clone { 'phabricator/libphutil':
        directory => '/usr/local/share/libphutil',
        branch    => 'wmf/stable',
    }

    git::clone { 'phabricator/arcanist':
        directory => '/usr/local/share/arcanist',
        branch    => 'wmf/stable',
        require   => Git::Clone['phabricator/libphutil'],
    }

    file { '/usr/local/bin/arc':
      ensure  => 'link',
      target  => '/usr/local/share/arcanist/bin/arc',
      owner   => 'root',
      group   => 'root',
      require => Git::Clone['phabricator/arcanist'],
    }
}
