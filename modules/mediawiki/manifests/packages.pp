# mediawiki package class
class mediawiki::packages {
  package { [ 'wikimedia-task-appserver', 'twemproxy' ]:
    ensure => latest;
  }
}
