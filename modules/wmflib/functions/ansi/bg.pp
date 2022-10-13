# SPDX-License-Identifier: Apache-2.0
# @summary function to change the background colour of text
# @param text the text to wrap
# @param colour the colour to use
# @param reset if true terminate text with the reset string
function wmflib::ansi::bg (
    String[1]            $text,
    Wmflib::Ansi::Colour $colour,
    Boolean              $reset = true
) >> String {
    $csi = "\u001B[" # lint:ignore:double_quoted_strings
    $colour_codes = {
        'black'   => 40,
        'red'     => 41,
        'green'   => 42,
        'yellow'  => 43,
        'blue'    => 44,
        'magenta' => 45,
        'cyan'    => 46,
        'white'   => 47,
    }
    $formated =  "${csi}${colour_codes[$colour]}m${text}"
    $reset.bool2str(wmflib::ansi::reset($formated), $formated)
}

