# Class: rspamd::ucl::file
# ===========================
#
# @summary manages a single UCL (Universal Configuration Language) config file
#
# @note This class is only for internal use, use rspam::config instead.
#
# @param file  the file to put the entry in
# @param comment an optional comment to be printed at the top of the file instead of
#   the default warning
# @param ensure whether the file should be `present` or `absent`
#
# @see rspamd::config
#
# @author Bernhard Frauendienst <puppet@nospam.obeliks.de>
#
define rspamd::ucl::file (
  Stdlib::Absolutepath $file        = $title,
  Optional[String] $comment         = undef,
  Enum['present', 'absent'] $ensure = 'present',
) {
  concat { $file:
    owner => 'root',
    # Use '0' for compatibity with Linux ("root") and FreeBSD ("wheel")
    group => 0,
    mode  => '0644',
    warn  => !$comment,
    order => 'alpha',
  }

  if ($comment) {
    concat::fragment { "rspamd ${file} UCL config 01 file warning comment":
      target  => $file,
      content => join(suffix(prefix(split($comment, '\n'), '# '), "\n")),
    }
  }
}
