# == Function: ordered_yaml
#
# Serialize a hash into YAML with lexicographically sorted keys.
#
# Ruby 1.9+ hashes maintain insertion order. The serialized form
# of hash is therefore stable across Puppet runs only insofar as
# the insertion order is stable. This function ensures hash keys
# are emitted in lexicographical order.
#
require 'yaml'
require 'json'

module Puppet::Parser::Functions
    newfunction(
      :ordered_yaml,
      :type => :rvalue,
      :doc  => <<-END
        Serialize a hash into YAML with lexicographically sorted keys.

        Ruby 1.9+ hashes maintain insertion order. The serialized form
        of hash is therefore stable across Puppet runs only insofar as
        the insertion order is stable. This function ensures hash keys
        are emitted in lexicographical order.
      END
    ) do |args|
        fail 'ordered_yaml() requires a single argument' unless args.length == 1
        Puppet::Parser::Functions.autoloader.loadall
        JSON.parse(function_ordered_json(args)).to_yaml
    end
end
