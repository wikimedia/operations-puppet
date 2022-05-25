# SPDX-License-Identifier: Apache-2.0
# @summary define to add some text to the motd
# @param ensure ensureable param
# @param message the message to add, use title by default
# @param priority the motd priority
define motd::message (
    Wmflib::Ensure $ensure   = present,
    String[1]      $message  = $title,
    Integer[0, 99] $priority = 50,
) {

    $content = @("CONTENT")
    #!/bin/sh
    printf "%s\n" "${message}"
    | CONTENT
    motd::script { $title:
        ensure   => $ensure,
        priority => $priority,
        content  => $content,
    }
}
