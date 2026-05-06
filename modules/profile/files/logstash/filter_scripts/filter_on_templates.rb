# SPDX-License-Identifier: Apache-2.0
# filter_on_templates.rb
# Logstash Ruby script to strip incompatible fields based on type described in the latest index template.
# @version 2.0.1

def register(params)
  @types_map = {  # TODO: This mapping is incomplete.  You can help by expanding it.
                  :date         => [DateTime, LogStash::Timestamp],
                  :keyword      => [String],
                  :text         => [String],
                  :object       => [Hash],
                  :boolean      => [TrueClass, FalseClass],
                  :float        => [Float, Integer],
                  :geo_point    => [Hash],
                  :half_float   => [Float, Integer],
                  :integer      => [Integer],
                  :ip           => [String],
                  :long         => [Integer],
                  :scaled_float => [Float, Integer],
                  # Non-OpenSearch data type indicating a namespace that is included in the fully-expanded template mapping.
                  # See: get_template_namespaces()
                  :parent       => []
  }
  template_file = Dir.glob(params['glob_pattern']).sort.last
  @template = JSON.load(File.read(template_file))
  @dynamic_template_objects = get_dynamic_template_namespaces(@template['mappings']['dynamic_templates'])
  # @excluded_dynamic_template_namespaces = @dynamic_template_objects.map { |k, _| k.split('[*]')[0] }
  @template_namespaces = get_template_namespaces(@template['mappings']['properties'])
  # limit deep inspection to only indexed objects and not path-matched dynamic templates
  @template_indexed_objects = @template_namespaces.select { |_, v| v[:type] == :object && v[:indexed] }
                                                  .reject { |k, _| @dynamic_template_objects.keys.include?(k) }
  @template_unindexed_objects = @template_namespaces.select { |_, v| v[:type] == :object && !v[:indexed] }
  @template_geo_points = @template_namespaces.select{ |_, v| v[:type] == :geo_point && v[:indexed] }
  @template_dates = @template_namespaces.select{ |_, v| v[:type] == :date && v[:indexed] }
end

# Check if the provided data type is one of the provided valid types.
#
# @param data [Object] The data supplied by event.get()
# @param valid_types [Array] Valid data types
# @return [Boolean]
def data_type_correct?(data, valid_types)
  valid_types.map { |t| data.is_a?(t) }.include? true
end

# Check if all values in an array are one of the valid types.
#
# @param values [Array] The values to inspect
# @param valid_types [Array] Valid data types
# @return [Boolean]
def array_value_types_correct?(values, valid_types)
  values.map { |value| data_type_correct?(value, valid_types)}.all?
end

# Remove event at namespace from the event and the event_namespaces hash
#
# @param namespace [String] The namespace to remove
# @param event [LogStash::Event] The event being handled
# @param event_namespaces [Hash] The event_namespaces hash
# @return [NilClass]
def purge_event(namespace, event, event_namespaces)
  event.remove(namespace)
  event_namespaces.delete(namespace)
  namespace = namespace[0, namespace.rindex('[')]
  # go up the namespace tree looking for empty hashes and clean them up
  until namespace.empty?
    entity = event.get(namespace)
    event.remove(namespace) if entity.is_a?(Hash) && entity.empty?
    namespace = namespace[0, namespace.rindex('[')]
  end
end

# Build up a list of namespaces from dynamic template definitions.
# Warning: only handles one globbing field, e.g. metrics.puppet.runtime.*.seconds
#
# @param dynamic_templates [Array] The list of dynamic templates.
# @return [Hash]
def get_dynamic_template_namespaces(dynamic_templates)
  output = {}
  dynamic_templates.each do |dt|
    # default ECS dynamic mapping settings as of ecs 1.11.0
    next if dt.keys.include?('strings_as_keyword')
    dt.each_value do |settings|
      next unless settings['path_match']
      # convert dot-delimited to bracketed namespace
      full_ns = "[#{settings['path_match'].gsub(/\./, '][')}]"
      parent, child = full_ns.split('[*]')
      # we'll use the parent (namespace before the glob) as the key so that we
      # can use the keys to exclude it from the list of objects
      output[parent] = {
        :type => settings['mapping']['type'].to_sym,
        :child => child
      }
    end
  end
  output
end

# Build up a fully-expanded list of namespaces from the template.
# This is a fairly expensive operation and is meant to be cached at plugin registration.
# Warning: Recursive function.
#
# "Fully-expanded" here means we're also including parent namespaces in the output keys. e.g.
#   {
#     '[log]' => { :type => 'parent', :indexed => true }
#     '[log][level]' => { :type => 'keyword', :indexed => true }
#     '[log][syslog]' => { :type => 'parent', :indexed => true }
#     '[log][syslog][facility]' => { :type => 'parent', :indexed => true }
#     '[log][syslog][facility][code]' => { :type => 'long', :indexed => true }
#   }
#
# @param template [Object] The object being descended into.
# @param key [String] The hash key being handled.
# @param namespace [String] The namespace this function has built up thus far.
# @param output [Array] The response object that has built up so far.
# @return [Hash]
def get_template_namespaces(template, key = '', namespace = '', output = {})
  namespace = key.empty? ? '' : "#{namespace}[#{key}]"
  # If we're descending into an object with properties, skip directly into the properties object.
  if template['properties']
    output[namespace] = {:type => :parent, :indexed => true}
    template['properties'].each do |k, v|
      get_template_namespaces(v, k, namespace, output)
    end
    return
  end

  # If we've discovered a namespace with a type field, add it to the output.
  if template['type']
    # geo_points are special objects containing only 'lat' and 'lon' fields with a float value
    # the index template does not describe this, so we must handle it here
    if template['type'].to_sym == :geo_point
      output["#{namespace}[lat]"] = { :type => :float, :indexed => true }
      output["#{namespace}[lon]"] = { :type => :float, :indexed => true }
    end
    # populate the namespace with
    # "enabled" boolean property is for objects
    # "index" boolean property is for all other types
    output[namespace] = {
      :type => template['type'].to_sym,
      :indexed => !(template['enabled'] == false || template['index'] == false)
    }
    return
  end

  # This snippet allows us to pass in the template's mappings.properties directly
  # without iterating over the hash in register()
  if template.is_a?(Hash)
    template.each do |k, v|
      get_template_namespaces(v, k, namespace, output)
    end
  end
  output
end

# Build up a list of namespaces from the event.
# Warning: Recursive function.
#
# @param evt [Hash] The object being descended into.
# @param excluded_namespaces [Array] Namespaces to exclude when building up the output.  Default: []
# @param key [String] The hash key being handled.
# @param namespace [String] The namespace this function has built up thus far.
# @param output [Array] The response object that has built up so far.
# @return [Hash]
def get_namespaces(evt, excluded_namespaces = [], key = '', namespace = '', output = {}) # rubocop:disable Metrics/ParameterLists
  namespace = key.empty? ? '' : "#{namespace}[#{key}]"
  return if excluded_namespaces.include?(namespace)

  output[namespace] = evt.class unless evt.is_a?(Hash)

  if evt.is_a?(Hash)
    output[namespace] = evt.class if evt.empty?
    evt.each do |k, v|
      get_namespaces(v, excluded_namespaces, k, namespace, output)
    end
  end

  output
end

# The filter required by the Ruby plugin.
def filter(event)
  # Collect invalid namespaces for reporting
  # Pass through existing errors
  errors = {
    :no_such_field => event.get('[normalized][dropped][no_such_field]'),
    :field_type_mismatch => event.get('[normalized][dropped][field_type_mismatch]')
  }
  errors[:no_such_field] = [] unless errors[:no_such_field].is_a?(Array)
  errors[:field_type_mismatch] = [] unless errors[:field_type_mismatch].is_a?(Array)
  errors[:unknown_data_type] = [] unless errors[:unknown_data_type].is_a?(Array)

  # performance optimization: remove objects and geo_points from the full event_namespaces list
  # these excluded namespaces require special treatment
  excluded_namespaces = [].concat(@template_indexed_objects.keys)
                          .concat(@template_geo_points.keys)
                          .concat(@template_unindexed_objects.keys)
                          .concat(@dynamic_template_objects.keys)
                          .concat(@template_dates.keys)
  event_namespaces = get_namespaces(event.to_hash, excluded_namespaces)

  # explicitly not handling ecs.version checking here
  # 1. Logstash gates this filter on ecs.version
  # 2. We do not want to tie ecs functionality to an explicit ecs version.
  #    As of 2025-06, we have 6 different versions and two major versions
  #    producing ECS logs in production.

  # handle dynamic template objects
  @dynamic_template_objects.each do |template_namespace, properties|
    entity = event.get(template_namespace)
    next unless entity.is_a?(Hash)
    entity.each do |k, v|
      next if data_type_correct?(v[properties[:child].gsub(/\[|\]/, '')], @types_map[properties[:type]])
      entity_namespace = "#{template_namespace}[#{k}]"
      errors[:field_type_mismatch].append(entity_namespace)
      purge_event(entity_namespace, event, event_namespaces)
    end
  end

  # handle templated objects
  @template_indexed_objects.each_key do |template_namespace|
    entity = event.get(template_namespace)
    next unless entity.is_a?(Hash)
    # indexed objects must be one level deep and must be keyword-compatible
    entity.each do |key, value|
      next if data_type_correct?(value, @types_map[:keyword])
      if value.is_a?(Array)
        next if value.map { |v| data_type_correct?(v, @types_map[:keyword]) }.all?(true)
      end
      # if we reach here, we've found a field type mismatch
      entity_namespace = "#{template_namespace}[#{key}]"
      errors[:field_type_mismatch].append(entity_namespace)
      purge_event(entity_namespace, event, event_namespaces)
    end
  end

  # handle templated geo_points
  @template_geo_points.each_key do |template_namespace|
    entity = event.get(template_namespace)
    next if entity.nil?
    unless entity.is_a?(Hash)
      errors[:field_type_mismatch].append(template_namespace)
      purge_event(template_namespace, event, event_namespaces)
      next
    end
    entity.each do |k, v|
      # check for invalid fields
      unless ['lat', 'lon'].include?(k)
        key = "#{template_namespace}[#{k}]"
        errors[:no_such_field].append(key)
        purge_event(key, event, event_namespaces)
      end
      # check for type mismatches
      unless v.is_a?(Float) # rubocop:disable Style/Next
        key = "#{template_namespace}[#{k}]"
        errors[:field_type_mismatch].append(key)
        purge_event(key, event, event_namespaces)
      end
    end
  end

  # handle template dates
  @template_dates.each do |template_namespace, properties|
    entity = event.get(template_namespace)
    next if entity.nil?
    if entity.is_a?(String)
      begin
        dt = DateTime.parse(entity)
      rescue Date::Error
        errors[:field_type_mismatch].append(template_namespace)
        purge_event(template_namespace, event, event_namespaces)
        next
      end
      # Warning: this is silly.  It's fast, but detection could probably be improved.
      next if entity.slice(0, 19) == dt.iso8601.slice(0, 19)
    end
    unless data_type_correct?(entity, @types_map[properties[:type]])
      errors[:field_type_mismatch].append(template_namespace)
      purge_event(template_namespace, event, event_namespaces)
    end
  end

  # handle remaining fields
  event_namespaces.each do |namespace, type|
    properties = @template_namespaces[namespace]
    if properties.nil?
      errors[:no_such_field].append(namespace)
      purge_event(namespace, event, event_namespaces)
      next
    end
    # if the data type is unsupported by this filter, surface the error in the normalized object rather than
    # just throwing an unhelpful _rubyexception unrelated to the change
    if @types_map[properties[:type]].nil?
      errors[:unknown_data_type].append("#{namespace}<#{properties[:type]}>")
      purge_event(namespace, event, event_namespaces)
      next
    end
    # keyword type supports an array of strings - don't reject these
    if type == Array && properties[:type] == :keyword
      next if array_value_types_correct?(event.get(namespace), @types_map[properties[:type]])
    end
    unless @types_map[properties[:type]].include?(type) # rubocop:disable Style/Next
      errors[:field_type_mismatch].append(namespace)
      purge_event(namespace, event, event_namespaces)
      next
    end
  end

  # Collect removed keys on reason for removal for later tracking
  event.set('[normalized][dropped][field_type_mismatch]', errors[:field_type_mismatch]) unless errors[:field_type_mismatch].empty?
  event.set('[normalized][dropped][no_such_field]', errors[:no_such_field]) unless errors[:no_such_field].empty?
  event.set('[normalized][dropped][unknown_data_type]', errors[:unknown_data_type]) unless errors[:unknown_data_type].empty?
  [event]
end

# run tests with `ruby filter_on_templates.rb
if __FILE__ == $PROGRAM_NAME
  require_relative '../helpers/filter_scripts_test_helper'
  require 'date_core'
  register({ "glob_pattern" => "../templates/ecs_1.11.0-*.json" })
  # override ecs template with an unsupported field type to test
  @template['mappings']['properties']['unknown_data_type'] = { 'type' => 'foo_type' }
  @template_namespaces = get_template_namespaces(@template['mappings']['properties'])

  fixture = {
    '@timestamp' => LogStash::Timestamp.new('1970-01-01T00:00:00.000Z'),
    'event' => {
      'created' => 'invalid',
      'ingested' => 0,
      'duration' => 0.849,
      'type' => ['access', 'connection']
    },
    'unknown_data_type' => 'nope',
    'labels' => {
      'valid_string' => 'foo',
      'invalid_int' => 1,
      'invalid_float' => 1.1,
      'invalid_array' => ['foo', 1],
      'valid_array' => ['foo', 'bar'],
      'illegal_object' => {
        'foo' => 'I should not exist.',
      },
      'illegal_hash_in_array' => [{ 'foo' => 'bar', 'baz' => 1 }, 'string'],
      'illegal_array_in_array' => [['foo'], 0]
    },
    'message' => 'I am valid.',
    'undefined_field' => 'I am undefined.',
    'log' => 'I should be a hash.',
    'client' => {
      'user' => 'I should be a hash.',
      'geo' => {
        'location' => {
          'lat' => 45.505918,
          'lon' => -73.614830,
          'undefined_field' => 0.1
        },
        'city_name' => {},
        'undefined_field' => 'I am undefined.'
      },
      'nat' => {
        'ip' => '0.0.0.0'
      }
    },
    'destination' => {
      'port' => 10_025
    },
    'observer' => {
      'geo' => {
        'location' => 0
      }
    },
    'user' => {
      'extra' => {
        'valid_top_level_string' => 'Valid!',
        'valid_top_level_int' => 1,
        'valid_top_level_float' => 1.1,
        'valid_nested' => {
          'foo' => 'bar',
          'valid_nested' => {
            'baz' => 'quux'
          }
        }
      }
    },
    'metrics' => {
      'puppet' => {
        'runtime' => { 'valid' => { 'seconds' => 0.23 },
          'invalid_string' => 'foo',
          'invalid_object' => {
            'seconds' => 'foo',
            'invalid_unit' => 0.23,
            'invalid_hash' => { 'foo' => 'bar' },
            'invalid_array' => ['foo', 0.23]
          }
        }
      }
    },
    'normalized' => {
      'dropped' => {
        'no_such_field' => ['foo']
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
    'type mismatches populate normalized.dropped.field_type_mismatch',
    event.get('[normalized][dropped][field_type_mismatch]') == [
      '[metrics][puppet][runtime][invalid_string]',
      '[metrics][puppet][runtime][invalid_object]',
      '[labels][invalid_int]',
      '[labels][invalid_float]',
      '[labels][invalid_array]',
      '[labels][illegal_object]',
      '[labels][illegal_hash_in_array]',
      '[labels][illegal_array_in_array]',
      '[observer][geo][location]',
      '[event][created]',
      '[event][ingested]',
      '[event][duration]',
      '[log]',
      '[client][user]',
      '[client][geo][city_name]'
    ]
  )
  assert_true(
    'undefined fields populate normalized.dropped.no_such_field',
    event.get('[normalized][dropped][no_such_field]') == [
      'foo',
      '[client][geo][location][undefined_field]',
      '[undefined_field]',
      '[client][geo][undefined_field]'
    ]
  )
  assert_true(
    'unknown data type fields populate normalized.dropped.unknown_data_type',
    event.get('[normalized][dropped][unknown_data_type]') == [
      '[unknown_data_type]<foo_type>'
    ]
  )
  assert_true(
    'labels is correct',
    event.get('[labels]') == {
      'valid_string' => 'foo',
      'valid_array' => ['foo', 'bar']
    }
  )
  assert_true(
    'message is correct',
    event.get('[message]') == 'I am valid.'
  )
  assert_true(
    'client top-level key is correct',
    event.get('[client]') == {
      'geo' => {
        'location' => {
          'lat' => 45.505918,
          'lon' => -73.61483
        }
      },
      'nat' => {
        'ip' => '0.0.0.0'
      }
    }
  )
  assert_true(
    'user top-level key is correct',
    event.get('[user]') == {
      'extra' => {
      'valid_top_level_string' => 'Valid!',
      'valid_top_level_int' => 1,
      'valid_top_level_float' => 1.1,
      'valid_nested' => {
        'foo' => 'bar',
        'valid_nested' => {
          'baz' => 'quux'
          }
        }
      }
    }
  )
  assert_true(
    'metrics top-level key is correct',
    event.get('[metrics]') == {
      'puppet' => {
        'runtime' => {
          'valid' => {
            'seconds' => 0.23
          }
        }
      }
    }
  )
  assert_nil(
    'undefined_field field is removed',
    event.get('[undefined_field]')
  )
  assert_nil(
    'log field is removed',
    event.get('[log]')
  )
  assert_nil(
    'observer field is removed',
    event.get('[observer]')
  )
end
