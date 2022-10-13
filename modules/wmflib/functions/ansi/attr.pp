# SPDX-License-Identifier: Apache-2.0
# @summary function to wrap a string in ansi colour formating
# @param text the text to wrap
# @param formating any formating to add e.g. bold, underlined
# @param reset if true terminate text with the reset string
function wmflib::ansi::attr (
    String[1]               $text,
    Wmflib::Ansi::Formating $format,
    Boolean                 $reset = true
) >> String {
    $csi = "\u001B[" # lint:ignore:double_quoted_strings
    $format_codes = {
        'normal'     => 0,
        'bold'       => 1,
        'underlined' => 4,
        'blinking'   => 5,
        'reverse'    => 7,
    }
    $formated = "${csi}${format_codes[$format]}m${text}"
    $reset.bool2str(wmflib::ansi::reset($formated), $formated)
}
