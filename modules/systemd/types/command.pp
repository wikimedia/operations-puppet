# As per the comment for Stdlib::Unixpath it is loose enough to also check for commands with arguments:
#    "this regex rejects any path component that does not start with "/" or is NUL"
# We make this an alias just in case Unixpath gets stricter
type Systemd::Command = Stdlib::Unixpath
