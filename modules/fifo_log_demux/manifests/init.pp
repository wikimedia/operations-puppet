# SPDX-License-Identifier: Apache-2.0
# == Class: fifo_log_demux
#
# Install and configure fifo-log-demux:
# https://github.com/wikimedia/operations-software-fifo-log-demux

class fifo_log_demux {
    package { 'fifo-log-demux':
        ensure => present,
    }
}
