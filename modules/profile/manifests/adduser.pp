# SPDX-License-Identifier: Apache-2.0

class profile::adduser {
    class { 'adduser': }
    contain adduser  # lint:ignore:wmf_styleguide
    # Ensure the correct systemd-sysusers, adduser and login.def config is in place before
    # any packages (which may create users) are installed
    Class['adduser'] -> Package<| |>
}
