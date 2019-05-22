# Trafficserver::Parent_rule provides partial support for Parent proxy rules.
# See https://docs.trafficserver.apache.org/en/latest/admin-guide/files/parent.config.en.html for more details.
# Example of a valid parent rule:
# dest_domain=. parent="127.0.0.1:3120, 127.0.0.1:3121" parent_is_proxy=false round_robin=strict
#
# [*dest_domain*]
#   A requested domain name, and its subdomains.
#
# [*parent*]
#   An ordered list of parent servers.
#
# [*parent_is_proxy*]
#   true:  The list of parents and secondary parents are proxy cache servers.
#   false: The list of parents and secondary parents are the origin servers.
#          The FQDN is removed from the http request line.
#
# [*round_robin*]
#   One of the following values:
#     consistent_hash: Consistent hash of the url so that one parent is chosen for a given url.
#     false: Round robin selection does not occur.
#     latched: The first parent in the list is marked as primary and is always chosen until connection errors
#              cause it to be marked down.
#     strict: Traffic Server machines serve requests strictly in turn.
#     true: Traffic Server determines the parent based on client IP address.

type Trafficserver::Parent_rule = Struct[{
    'dest_domain'     => String,
    'parent'          => Array[String],
    'parent_is_proxy' => Enum['true', 'false'], # lint:ignore:quoted_booleans
    'round_robin'     => Enum['consistent_hash', 'false', 'latched', 'strict', 'true'] # lint:ignore:quoted_booleans
}]
