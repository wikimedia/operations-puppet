# SPDX-License-Identifier: Apache-2.0
# Install bsection.py to help with searching multi-gigabyte log files.
class bsection{
    file { '/usr/local/bin/bsection':
        source => 'puppet:///modules/bsection/bsection.py',
        owner  => 'root',
        group  => 'root',
        mode   => '0555',
    }
}
