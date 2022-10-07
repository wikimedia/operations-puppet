# SPDX-License-Identifier: Apache-2.0
# dot_expander.rb
# Logstash Ruby script to expand dot-delimited fields into nested hashes
# @version 1.0.2

def register(params) end

def expand_dots(key, value)
  # Transforms a dot-delimited string "key" into nested objects with the final key set to value
  # ex. |'a.b.c.d', 'value'| to {'a' => {'b' => {'c' => {'d' => 'value'}}}}
  o = {}
  keys = key.split('.')
  o.default_proc = -> (h, k) { h[k] = Hash.new(&h.default_proc) }
  o.dig(*keys[0..-2])[keys.fetch(-1)] = value
  o
end

# rubocop:disable Metrics/BlockNesting
def deep_merge(source, dest)
# Merges source hash into dest hash and returns dest
#
# adapted from https://github.com/danielsdeleo/deep_merge
# The MIT License (MIT)
#
# Copyright (c) 2008-2016 Steve Midgley, Daniel DeLeo
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
  if source.kind_of?(Hash)
    source.each do |src_key, src_value|
      if dest.kind_of?(Hash)
        if dest[src_key]
          dest[src_key] = deep_merge(src_value, dest[src_key])
        else # dest[src_key] doesn't exist so we want to create and overwrite it (but we do this via deep_merge)
          # note: we rescue here b/c some classes respond to "dup" but don't implement it (Numeric, TrueClass, FalseClass, NilClass among maybe others)
          begin
            src_dup = src_value.dup # we dup src_value if possible because we're going to merge into it (since dest is empty)
          rescue TypeError
            src_dup = src_value
          end
          dest[src_key] = deep_merge(src_value, src_dup)
        end
      end
    end
  else
    dest = source
  end
  dest
end
# rubocop:enable Metrics/BlockNesting

def filter(event)
  # Filter entrypoint
  nested = {}
  event.to_hash.each do | key, value |
    next unless key.include? '.'

    # get the top level key and data from the event
    top_level_key = key.split('.')[0]
    entity = event.get(top_level_key)

    # if entity is a hash, add it to the output before merging
    nested[top_level_key] = entity if entity.is_a? Hash
    # otherwise, merging is impossible.  the object shall take its place in the output.

    nested = deep_merge(expand_dots(key, value), nested)
    event.remove(key)
  end
  nested.each do | key, value |
    event.set(key, value)
  end
  [event]
end
