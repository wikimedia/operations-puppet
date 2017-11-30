# Definition: rsync::get
#
# get files via rsync
#
# Parameters:
#   $source  - source to copy from
#   $path    - path to copy to, defaults to $name
#   $user    - username on remote system
#   $purge   - if set, rsync will use '--delete'
#   $exlude  - string to be excluded
#   $keyfile - path to ssh key used to connect to remote host, defaults to /home/${user}/.ssh/id_rsa
#   $timeout - timeout in seconds, defaults to 900
#
# Actions:
#   get files via rsync
#
# Requires:
#   $source must be set
#
# Sample Usage:
#
#  rsync::get { '/foo':
#    source  => "rsync://${rsyncServer}/repo/foo/",
#    require => File['/foo'],
#  } # rsync
#
define rsync::get (
  $source,
  $path = undef,
  $user = undef,
  $purge = undef,
  $exclude = undef,
  $keyfile = undef,
  $timeout = '900'
) {

  if $keyfile {
    $mykeyfile = $keyfile
  } else {
    $mykeyfile = "/home/${user}/.ssh/id_rsa"
  }

  if $user {
    $myuser = "-e 'ssh -i ${mykeyfile} -l ${user}' ${user}@"
  }
  else {
    $myuser = ''
  }

  if $purge {
    $mypurge = '--delete'
  } else {
      $mypurge = ''
  }

  if $exclude {
    $myexclude = "--exclude=${exclude}"
  } else {
      $myexclude = ''
  }

  if $path {
    $mypath = $path
  } else {
    $mypath = $name
  }

  $rsync_options = "-a ${mypurge} ${myexclude} ${myuser}${source} ${mypath}"

  exec { "rsync ${name}":
    command => "rsync -q ${rsync_options}",
    path    => [ '/bin', '/usr/bin' ],
    # perform a dry-run to determine if anything needs to be updated
    # this ensures that we only actually create a Puppet event if something needs to
    # be updated
    # TODO - it may make senes to do an actual run here (instead of a dry run)
    #        and relace the command with an echo statement or something to ensure
    #        that we only actually run rsync once
    onlyif  => "test `rsync --dry-run --itemize-changes ${rsync_options} | wc -l` -gt 0",
    timeout => $timeout,
  }
}
