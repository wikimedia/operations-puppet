# SPDX-License-Identifier: Apache-2.0
# normalize_labels.rb
# Logstash Ruby script to cast the type of all labels to string
# @version 1.1.0

def register(*) end

def filter(event)
  original_labels = event.get('labels')

  # nothing to do if labels is not a hash
  return [event] unless original_labels.instance_of? Hash

  # cast all labels to string
  original_labels.each do | key, value |
    if value.is_a?(Hash) || value.is_a?(Array)
      event.set("[labels][#{key}]", value.to_json)
      next
    end
    event.set("[labels][#{key}]", value.to_s)
  end

  [event]
end

if __FILE__ == $PROGRAM_NAME
  require_relative '../helpers/filter_scripts_test_helper'
  register({})

  fixture = {
    'labels' => {
      'bool' => false,
      'int' => 1,
      'float' => 3.14,
      'hash' => {'foo' => 0},
      'array' => ['foo', 0, true, 3.14],
      'nil' => nil
    },
    'type' => 'test',
    'http' => {
      'request' => {
        'headers' => {
          'foo' => { 'a' => 'b' }
        }
      }
    }
  }

  event = filter(Event.new(fixture))[0]

  # print the filtered output if first argument is 'debug'
  if ARGV[0] == 'debug'
    require 'json'
    puts(JSON.pretty_generate(event.to_hash))
  end

  assert_true(
    'bools are strings',
    event.get('[labels][bool]') == 'false'
  )
  assert_true(
    'ints are strings',
    event.get('[labels][int]') == '1'
  )
  assert_true(
    'floats are strings',
    event.get('[labels][float]') == '3.14'
  )
  assert_true(
    'hashes are strings',
    event.get('[labels][hash]') == '{"foo":0}'
  )
  assert_true(
    'arrays are strings',
    event.get('[labels][array]') == '["foo",0,true,3.14]'
  )
  assert_true(
    'nils are empty',
    event.get('[labels][nil]') == ''
  )
end
