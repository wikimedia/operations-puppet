# mediawiki package class
## TODO: rename to just mediawiki::packages after full transition to module
class mediawiki_new::packages {
  package { 'wikimedia-task-appserver':
    ensure => latest;
  }
}
