# SPDX-License-Identifier: Apache-2.0
# @summary function to Add a reset code to a string
# @param text the text to wrap
function wmflib::ansi::reset (
    String[1] $text,
) >> String {
    $reset = "\u001B[0m" # lint:ignore:double_quoted_strings
    $text.stdlib::end_with($reset).bool2str($text, "${text}${reset}")
}
