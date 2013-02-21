# mediawiki l10nupdate user
## TODO: rename to just mediawiki::users::l10update after full transition to module
class mediawiki_new::users::l10nupdate {
  ## l10nupdate user
  $authorized_key = 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAzcA/wB0uoU+XgiYN/scGczrAGuN99O8L7m8TviqxgX9s+RexhPtn8FHss1GKi8oxVO1V+ssABVb2q0fGza4wqrHOlZadcFEGjQhZ4IIfUwKUo78mKhQsUyTd5RYMR0KlcjB4UyWSDX5tFHK6FE7/tySNTX7Tihau7KZ9R0Ax//KySCG0skKyI1BK4Ufb82S8wohrktBO6W7lag0O2urh9dKI0gM8EuP666DGnaNBFzycKLPqLaURCeCdB6IiogLHiR21dyeHIIAN0zD6SUyTGH2ZNlZkX05hcFUEWcsWE49+Ve/rdfu1wWTDnourH/Xm3IBkhVGqskB+yp3Jkz2D3Q== l10nupdate@fenari'

  require groups::l10nupdate

  systemuser { 'l10nupdate': name => 'l10nupdate', home => '/home/l10nupdate', default_group => 10002 }

  file {
    "/home/l10nupdate/.ssh":
      require => Systemuser["l10nupdate"],
      owner => l10nupdate,
      group => l10nupdate,
      mode => 0500,
      ensure => directory;
    "/home/l10nupdate/.ssh/authorized_keys":
      require => File["/home/l10nupdate/.ssh"],
      owner => l10nupdate,
      group => l10nupdate,
      mode => 0400,
      content => $authorized_key;
  }
}
