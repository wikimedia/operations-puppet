# Define additional Postfix services.
#
# @example Define the Dovecot LDA service
#   include postfix
#   postfix::master { 'dovecot/unix':
#     chroot       => 'n',
#     command      => 'pipe flags=DRhu user=vmail:vmail argv=/path/to/dovecot-lda -f ${sender} -d ${recipient}',
#     unprivileged => 'n',
#     require      => Class['dovecot'],
#   }
#
# @param command
# @param service
# @param ensure
# @param private
# @param unprivileged
# @param chroot
# @param wakeup
# @param limit
#
# @see puppet_classes::postfix postfix
# @see puppet_defined_types::postfix::main postfix::main
#
# @since 1.0.0
define postfix::master (
  String                                                           $command,
  Pattern[/(?x) ^ [^\/]+ \/ (?:inet|unix(?:-dgram)?|fifo|pass) $/] $service      = $title,
  Enum['present', 'absent']                                        $ensure       = 'present',
  Optional[Enum['-', 'n', 'y']]                                    $private      = undef,
  Optional[Enum['-', 'n', 'y']]                                    $unprivileged = undef,
  Optional[Enum['-', 'n', 'y']]                                    $chroot       = undef,
  Optional[Pattern[/(?x) ^ (?: - | \d+ [?]? ) $/]]                 $wakeup       = undef,
  Optional[Pattern[/(?x) ^ (?: - | \d+ ) $/]]                      $limit        = undef,
) {

  include postfix

  postfix_master { $service:
    ensure       => $ensure,
    command      => $command,
    private      => $private,
    unprivileged => $unprivileged,
    chroot       => $chroot,
    wakeup       => $wakeup,
    limit        => $limit,
    target       => "${postfix::conf_dir}/master.cf",
    require      => Class['postfix::config'],
    notify       => Class['postfix::service'],
  }
}
