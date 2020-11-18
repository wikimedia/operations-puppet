# Setup Kernel 4.19 and rasdaemon on stretch hosts
#
# See:
#   * T205396
#   * T262527

class profile::base::linux419(
    Boolean $enable = lookup('profile::base::linux419::enable', { 'default_value' => false }),
) {
    # only for stretch
    if $enable and debian::codename::eq('stretch') {
        ensure_packages('linux-image-4.19-amd64')

        # real-hardware specific
        unless $facts['is_virtual'] {
            ensure_packages('rasdaemon')
            base::service_auto_restart { 'rasdaemon': }

            # Mask mcelog systemd unit if this host is *running*
            # a kernel >= 4.12.
            if versioncmp($::kernelversion, '4.12') >= 0 {
                systemd::mask { 'mcelog.service': }
            }
        }
    }
}
