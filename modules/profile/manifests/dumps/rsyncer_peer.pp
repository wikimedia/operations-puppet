class profile::dumps::rsyncer_peer.pp {
  class {'dumps::rsync::default.pp':}
  class {'dumps::rsync::memfix':}
  class {'dumps::rsync::peers':}
}
