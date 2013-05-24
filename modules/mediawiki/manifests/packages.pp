# mediawiki package class
class mediawiki::packages {

  if $::realm == 'labs' {
    file { '/usr/local/apache':
      ensure       => link,
      target => '/data/project/apache',
      # Create link before wikimedia-task-appserver attempts
      # to create /usr/local/apache/common.
      before => Package['wikimedia-task-appserver'],
    }
  }

  package { 'wikimedia-task-appserver':
    ensure => latest;
  }
}
