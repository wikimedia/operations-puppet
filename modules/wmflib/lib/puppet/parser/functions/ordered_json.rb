# == Function: ordered_json
#
# Serialize a hash into JSON with lexicographically sorted keys.
#
# Because the order of keys in Ruby 1.8 hashes is undefined, 'to_pson'
# is not idempotent: i.e., the serialized form of the same hash object
# can vary from one invocation to the next. This causes problems
# whenever a JSON-serialized hash is included in a file template,
# because the variations in key order are picked up as file updates by
# Puppet, causing Puppet to replace the file and refresh dependent
# resources on every run.
#
# Copyright 2014 Ori Livneh
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
def ordered_json(o)
    case o
    when Array
        '[' + o.map { |x| ordered_json(x) }.join(', ') + ']'
    when Hash
        '{' + o.sort.map { |k,v| k.to_pson + ': ' + ordered_json(v) }.join(', ') + '}'
    else
        o.include?('.') ? Float(o).to_s : Integer(o).to_s rescue o.to_pson
    end
end

module Puppet::Parser::Functions
    newfunction(:ordered_json, :type => :rvalue) do |args|
        fail 'ordered_json() requires an argument' if args.empty?
        ordered_json(args.inject(:merge))
    end
end
