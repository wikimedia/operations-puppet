# SPDX-License-Identifier: Apache-2.0
# == Class: fifo_log_demux
#
# Install and configure fifo-log-demux

class fifo_log_demux {
    # Not a hard requirement but handy to have to test fifo-log-demux
    ensure_packages('socat')

    package { 'fifo-log-demux':
        ensure => present,
    }
}
