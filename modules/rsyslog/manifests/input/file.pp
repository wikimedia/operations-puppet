# SPDX-License-Identifier: Apache-2.0
#
# rsyslog::input::file - ingest a log file with rsyslog imfile for processing/shipping
#
# see https://www.rsyslog.com/doc/v8-stable/configuration/modules/imfile.html for full imfile documentation
#
# $path - Input file path glob. Wildcards supported in both file and directories
# $syslog_tag_prefix - Prefix to be applied to syslog tag field (defaults to 'imfile')
# $syslog_tag - Desired syslog tag (useful for example with filtering/shipping)
# $priority - Rsyslog conf file priority number (used in filename prefix)
# $reopen_on_truncate - Reopen input file when it was truncated (inode unchanged but file size on disk is less than current offset in memory).
# $startmsg_regex - Regex pattern matching the beginning of multi-line log event. Log lines will be appended until the next match.
#
define rsyslog::input::file (
    String  $path,
    Wmflib::Ensure $ensure                       = present,
    Enum['on','off'] $reopen_on_truncate         = 'on',
    Pattern[/[a-zA-Z0-9_-]+/] $syslog_tag_prefix = 'input-file',
    Pattern[/[a-zA-Z0-9_-]+/] $syslog_tag        = $title,
    Integer $priority                            = 10,
    Optional[String] $startmsg_regex             = undef,
    Enum['on','off'] $addmetadata                = 'off',
    Enum['on','off'] $addceetag                  = 'off',
) {
    rsyslog::conf { "${syslog_tag_prefix}-${title}":
        ensure   => $ensure,
        content  => template('rsyslog/input/file.erb'),
        priority => $priority,
        require  => Rsyslog::Conf['imfile'],
    }

    if $ensure == 'present' and !defined(Rsyslog::Conf['imfile']) {
        rsyslog::conf { 'imfile':
            content  => 'module(load="imfile")',
            priority => 00,
        }
    }
}
