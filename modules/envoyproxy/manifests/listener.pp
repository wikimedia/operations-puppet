# SPDX-License-Identifier: Apache-2.0
# @summary defines a file containing an envoy listener definition
#
# @param content
#   The content of the listener definition
#
# @param priority
#   The priority of this listener. Listeners defintions with higher priority get checked first.
define envoyproxy::listener(
  String $content,
  Integer[0,99] $priority = 50,
) {
  envoyproxy::conf{ $title:
    content   => $content,
    conf_type => 'listener',
    priority  => $priority,
  }
}
