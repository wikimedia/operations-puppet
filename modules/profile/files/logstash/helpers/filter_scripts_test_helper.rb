# SPDX-License-Identifier: Apache-2.0
# test_helper.rb
# Helper class and functions for testing ruby scripts
#
# This IS NOT A VALID LOGSTASH RUBY PLUGIN

require 'json'

def assert_true(what, truth)
  raise "#{what} is not true" unless truth == true
end

def assert_false(what, truth)
  raise "#{what} is not false" unless truth == false
end

def assert_nil(what, result)
  raise "#{what} is not nil" unless result.nil?
end

class Event
  # Emulates a Logstash event by reimplementing event methods

  def initialize(event)
    raise 'Provided event must be a hash.' unless event.is_a? Hash
    @event = event
  end

  def get(selector)
    # Returns the key at the given selector
    selector = _parse_path(selector)
    cur = @event
    depth = 0
    selector.each do |key|
      break unless cur.is_a? Hash
      cur = cur[key]
      depth += 1
    end

    return cur if depth == selector.length
  end

  def set(selector, value)
    # Sets the value of the event at the given selector
    _update(@event, _parse_path(selector), value)
  end

  def remove(selector)
    # Removes the key at the given selector
    _remove(@event, _parse_path(selector))
  end

  def cancel
    # Set metadata for testing purposes - not real behavior
    _update(@event, _parse_path('[@metadata][cancelled]'), true)
  end

  def to_hash
    # Returns a new copy of the event as a hash
    JSON.parse(@event.to_json)
  end

  def evt
    @event
  end

  def _parse_path(selector)
    # Parses a selector into an array
    #   When 'foo', returns [ 'foo' ]
    #   When '[foo][bar]', returns [ 'foo', 'bar' ]

    # assume selector path is a single key if no square bracket
    return [selector] if selector[0] != '['
    # extract path to array
    selector.scan(/\[[a-zA-Z0-9@_\-\.]+\]/).map { |k| k[1..-2] }
  end
  private :_parse_path

  def _update(evt, selector, value)
    # Recurses down into the event and sets the key to the value
    cur = selector.shift
    evt[cur] = {} if evt[cur].nil?
    return evt[cur] = value if selector.empty?
    evt[cur][_update(evt[cur], selector, value)]
  end
  private :_update

  def _remove(evt, selector)
    # Recurses down into the event and removes the key defined by the selector
    cur = selector.shift
    return evt.delete(cur) if selector.empty?
    evt[cur][_remove(evt[cur], selector)]
  end
  private :_remove
end

# run tests with `ruby filter_scripts_test_helper.rb`
if __FILE__ == $PROGRAM_NAME
  data = {
    "@metadata" => {
      "plugin_type" => "foo"
    },
    "a" => {
      "b" => {
        "c" => true
      }
    },
    "b" => ['c']
  }
  e = Event.new(data)
  assert_true(
    '@metadata.plugin_type is foo',
    e.get('[@metadata][plugin_type]') == 'foo'
  )
  assert_true(
    'a.b.c is true',
    e.get('[a][b][c]')
  )
  assert_true(
    'a is expected object',
    e.get('a') == {'b' => {'c' => true}}
  )
  assert_nil(
    'a.c is nil',
    e.get('[a][c]')
  )
  assert_nil(
    'b.c is nil',
    e.get('[b][c]')
  )
  e.set('a', 'foo')
  assert_true(
    'a is now foo',
    e.get('a') == 'foo'
  )
  e.remove('a')
  assert_nil(
    'a is removed',
    e.get('a')
  )
  e.set('[a][b][c]', true)
  assert_true(
    'a.b.c is restored',
    e.get('[a][b][c]')
  )
  e.cancel
  assert_true(
    'event is cancelled',
    e.get('[@metadata][cancelled]')
  )
end
