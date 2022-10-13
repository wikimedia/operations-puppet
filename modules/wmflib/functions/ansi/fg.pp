# SPDX-License-Identifier: Apache-2.0
# @summary function to change the forground colour of text
# @param text the text to wrap
# @param colour the colour to use
# @param reset if true terminate text with the reset string
function wmflib::ansi::fg (
    String[1]            $text,
    Wmflib::Ansi::Colour $colour,
    Boolean              $reset = true
) >> String {
    $csi = "\u001B[" # lint:ignore:double_quoted_strings
    $colour_codes = {
        'black'   => 30,
        'red'     => 31,
        'green'   => 32,
        'yellow'  => 33,
        'blue'    => 34,
        'magenta' => 35,
        'cyan'    => 36,
        'white'   => 37,
    }
    $formated =  "${csi}${colour_codes[$colour]}m${text}"
    $reset.bool2str(wmflib::ansi::reset($formated), $formated)
}

