# This function allows puppet code to access values we got from etcd
# and are stored on the puppetmasters via the
# profile::conftool::state profile.
#
# This function should be used with care, this is kind-of an antipattern. It still
# has the advantage over just querying conftool directly from puppet that
# we reduce the number of queries performed, and make their reliability better.

function mediawiki::state(String $key) >> Variant[Hash, String] {
    $data = loadyaml('/etc/conftool-state/mediawiki.yaml')
    unless has_key($data, $key) {
        fail("Could not find key ${key} in the mediawiki state file")
    }
    $data[$key]
}
