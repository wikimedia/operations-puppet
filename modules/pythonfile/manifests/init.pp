#  This should behave the same as the puppet 'file' type,
#  but will also link the file to the appropriate dist-packages
#  dir, depending on the installed pythin version.

define pythonfile ( backup = undef,
                    checksum = undef,
                    content = undef,
                    ctime = undef,
                    ensure = undef,
                    force = undef,
                    group = undef,
                    ignore = undef,
                    links = undef,
                    mode = undef,
                    mtime = undef,
                    owner = undef,
                    path = undef,
                    provider = undef,
                    purge = undef,
                    recurse = undef,
                    recurselimit = undef,
                    replace = undef,
                    selinux_ignore_defaults = undef,
                    selrange = undef,
                    selrole = undef,
                    seltype = undef,
                    seluser = undef,
                    source = undef,
                    sourceselect = undef,
                    target = undef,
                    type = undef ) {
  # Do everything that 'file' would do...
  file {
    $name:
      backup => $backup,
      checksum => $checksum,
      content => $content,
      ctime => $ctime,
      ensure => $ensure,
      force => $force,
      group => $group,
      ignore => $ignore,
      links => $links,
      mode => $mode,
      mtime => $mtime,
      owner => $owner,
      path => $path,
      provider => $provider,
      purge => $purge,
      recurse => $recurse,
      recurselimit => $recurselimit,
      replace => $replace,
      selinux_ignore_defaults => $selinux_ignore_defaults,
      selrange => $selrange,
      selrole => $selrole,
      seltype => $seltype,
      seluser => $seluser,
      source => $source,
      sourceselect => $sourceselect,
      target => $target,
      type => $type
  }

  $basename = regsubst($name, '.*/', "", "G")

  # and link to all available python dirs.
  exec { "${name}-link-to-python2.6":
      command => "/bin/ln -s $name /usr/lib/python2.6/dist-packages/$basename",
      creates => "/usr/lib/python2.6/dist-packages/$basename",
      onlyif => "/usr/bin/test -d /usr/lib/python2.6/dist-packages";
  }
  exec { "${name}-link-to-python2.7":
      command => "/bin/ln -s $name /usr/lib/python2.7/dist-packages/$basename",
      creates => "/usr/lib/python2.7/dist-packages/$basename",
      onlyif => "/usr/bin/test -d /usr/lib/python2.7/dist-packages";
  }
  exec { "${name}-link-to-python3":
      command => "/bin/ln -s $name /usr/lib/python3/dist-packages/$basename",
      creates => "/usr/lib/python3/dist-packages/$basename",
      onlyif => "/usr/bin/test -d /usr/lib/python3/dist-packages";
  }
}
