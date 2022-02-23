# @summary define to add some text to the motd
# @param ensure ensureable param
# @param message the message to add
# @param priority the motd priority
define motd::message (
    String[1]      $message,
    Wmflib::Ensure $ensure   = present,
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
