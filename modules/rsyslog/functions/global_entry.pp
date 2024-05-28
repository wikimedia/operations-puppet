# SPDX-License-Identifier: Apache-2.0
# Add a global config option to rsyslog[1]
#
# [1]: https://www.rsyslog.com/doc/rainerscript/global.html
function rsyslog::global_entry(
    String[1] $key,
    String[1] $value,
) >> Type[Concat::Fragment] {
    $concat_rsc = concat::fragment { "${rsyslog_global_conf}-${key}":
        target  => $rsyslog::rsyslog_global_conf,
        order   => $key,
        content => epp(
            'rsyslog/global_entry.epp',
            {
                'key'   => $key,
                'value' => $value,
            }
        ),
    }
    $concat_rsc[0]
}
