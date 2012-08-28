# puppetlabs-rsync #

puppetlabs-rsync manages rsync clients, repositories, and servers as well as
providing defines to easily grab data via rsync.

# Definition: rsync::get #

get files via rsync

## Parameters: ##
    $source  - source to copy from
    $path    - path to copy to, defaults to $name
    $user    - username on remote system
    $purge   - if set, rsync will use '--delete'
    $exlude  - string to be excluded
    $keyfile - ssh key used to connect to remote host
    $timeout - timeout in seconds, defaults to 900

## Actions: ##
  get files via rsync

## Requires: ##
  $source must be set

## Sample Usage: ##
    # get file 'foo' via rsync
    rsync::get { '/foo':
      source  => "rsync://${rsyncServer}/repo/foo/",
      require => File['/foo'],
    }

# Definition: rsync::server::module #

sets up a rsync server

## Parameters: ##
    $path           - path to data
    $comment        - rsync comment
    $motd           - file containing motd info
    $read_only      - yes||no, defaults to yes
    $write_only     - yes||no, defaults to no
    $list           - yes||no, defaults to no
    $uid            - uid of rsync server, defaults to 0
    $gid            - gid of rsync server, defaults to 0
    $incoming_chmod - incoming file mode, defaults to 644
    $outgoing_chmod - outgoing file mode, defaults to 644

## Actions: ##
  sets up an rsync server

## Requires: ##
  $path must be set

## Sample Usage: ##
    # setup default rsync repository
    rsync::server::module{ 'repo':
      path    => $base,
      require => File[$base],
    }
