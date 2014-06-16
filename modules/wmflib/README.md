= wmflib - wikimedia's shared functions module

Put parser functions here which are used by more than
one other puppet module, in order to avoid duplication.

Puppet auto-loads everything in /modules/*/lib so there
is no need to require the module or add any explicit
dependency. Just add the parser function in 
lib/puppet/parser/functions and it should become available
globally.

Currently we have just one function, ordered_json, which
allows us to export json from a ruby hash while maintaining
deterministic ordering of the keys so that we don't
have puppet detecting changed resources every time we
export the same data. This is needed because of the
non-deterministic ordering of ruby 1.8's hash structure.
An equivilent hash object is effectively different each
time puppet runs.

calling ordered_json(hash) will take care of sorting the
output so that you get an identical json string every time.

