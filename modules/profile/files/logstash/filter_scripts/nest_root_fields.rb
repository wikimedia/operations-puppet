# SPDX-License-Identifier: Apache-2.0
# nest_root_fields.rb
# Logstash Ruby script to copy all root fields into sub-fields of an object
# @version 1.0.2
#
# Example Logstash Filter:
# ruby {
#   path => "/etc/logstash/filter_scripts/nest_root_fields.rb"
#   script_params => {
#     "exclude" => [ "c" ]
#     "exclude_common_fields" => true
#     "target" => "labels"
#     "overwrite" => true
#   }
# }
#
# The above filter configuration would affect an event like so:
#
# Event In -> {
#   "labels": "overwrite me",
#   "a": "field a",
#   "b": "field b",
#   "c": "field c",
#   "host": "hostname1001"
# }
#
# Event Out -> {
#   "labels": {
#     "a": "field a",
#     "b": "field b"
#   }
#   "host": "hostname1001",
#   "c": "field c"
# }

def register(params)
  @exclude = params["exclude"] || []
  @target = params["target"]
  @overwrite = params["overwrite"]
  @exclude_common_fields = params["exclude_common_fields"]
  @common_fields = %w[
    logsource
    type
    host
    timestamp
    program
    message
    facility
    level
    path
    severity
    rsyslog.facility
    rsyslog.hostname
    rsyslog.programname
    rsyslog.severity
    rsyslog.timereported
  ]
  @exclude = @exclude.concat(@common_fields) if @exclude_common_fields
end

# get the event with an additional tag
def event_with_tag(event, value)
  tags = event.get("tags") || []
  tags.push(value)
  event.set("tags", tags)
  event
end

def filter(event)
  unless @target.nil? # skip if no target provided
    output = event.get(@target)

    if output.instance_of?(Hash)
      output = output.to_hash
    else
      output = {}
      # if target exists, is not hashable, and overwrite is not requested,
      # do nothing else but add a tag so we know it happened
      return [event_with_tag(event, '_nest_root_fields_unhashable_target_field')] unless @overwrite
    end

    event.to_hash.each_key do |k|
      next if k[0] == "@" # skip meta fields
      next if k == "tags" # skip tags
      next if @exclude.include?(k) # skip excluded fields
      output[k] = event.get(k)
      event.remove(k)
    end

    event.set(@target, output)

  end
  [event]
end

# run tests with `ruby convert_numeric_fields_on_templates.rb
if __FILE__ == $PROGRAM_NAME
  require_relative '../helpers/filter_scripts_test_helper'

  def print_json(event)
    # print the filtered output if first argument is 'debug'
    if ARGV[0] == 'debug'
      require 'json'
      puts(JSON.pretty_generate(event.to_hash))
    end
  end

  def fixture
    {
      'labels' => 'foo',
      'host' => 'alert2002',
      'summary' => 'Increased Speed Index for en.wiki on desktop',
      'tool' => 'webpagetest',
      'alertname' => 'Increased Speed Index for en.wiki on desktop',
      'description' => 'All three URLS for enwiki (using Firefox desktop) fired with a difference of 100 ms.'
    }
  end

  register({
    'exclude' => ['description', 'summary'],
    'exclude_common_fields' => true,
    'target' => 'labels',
    'overwrite' => true
  })
  event = filter(Event.new(fixture))[0]
  print_json(event)

  assert_true(
    'summary field is at root',
    event.get('summary') == 'Increased Speed Index for en.wiki on desktop'
  )
  assert_true(
    'description field is at root',
    event.get('description') == 'All three URLS for enwiki (using Firefox desktop) fired with a difference of 100 ms.'
  )

  assert_true(
    'labels is populated with overwrite',
    event.get('labels') == {'labels' => 'foo', 'tool' => 'webpagetest', 'alertname' => 'Increased Speed Index for en.wiki on desktop'}
  )
  register({
    'exclude' => ['description', 'summary'],
    'exclude_common_fields' => false,
    'target' => 'labels',
    'overwrite' => true
  })
  event = filter(Event.new(fixture))[0]
  print_json(event)

  assert_true(
    'common fields are moved when exclude_common_fields == false',
    event.get('labels')['host'] == 'alert2002'
  )

  register({
    'exclude' => ['description', 'summary'],
    'exclude_common_fields' => false,
    'target' => 'labels',
    'overwrite' => false
  })
  event = filter(Event.new(fixture))[0]
  print_json(event)

  assert_true(
    'setting override == false causes event to be tagged',
    event.get('tags') == ['_nest_root_fields_unhashable_target_field']
  )
end
