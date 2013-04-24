# Wikimedia uses a small tmpfs disk to help soften I/O on the contint server.
# A typical use cases are the MediaWiki sqlite files
class contint::tmpfs {

  include jenkins::user

  # Setup tmpfs to write SQLite files to
  file { '/var/lib/jenkins/tmpfs':
    ensure  => directory,
    mode    => '0755',
    owner   => jenkins,
    group   => jenkins,
    require => [ User['jenkins'], Group['jenkins'] ],
  }

  mount { '/var/lib/jenkins/tmpfs':
    ensure  => mounted,
    device  => 'tmpfs',
    fstype  => 'tmpfs',
    options => 'noatime,defaults,size=512M,mode=755,uid=jenkins,gid=jenkins',
    require => [ User['jenkins'], Group['jenkins'],
      File['/var/lib/jenkins/tmpfs'] ],
  }

}
