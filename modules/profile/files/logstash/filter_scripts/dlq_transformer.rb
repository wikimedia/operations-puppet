# dlq_transformer.rb
# Logstash Ruby script transform a dead letter queue event into the expected format
# @version: 1.0.0

def register(params) end

def filter(event)
  # Make a copy
  original_event = event.to_hash

  # Remove all original keys, except special ones
  original_event.each_key do | k |
    next if k[0] == '@'
    event.remove(k)
  end

  # Rebuild the event in the new format
  event.set('type', 'dlq')
  event.set('plugin_type', event.get('[@metadata][dead_letter_queue][plugin_type]'))
  event.set('message', event.get('[@metadata][dead_letter_queue][reason]'))
  event.set('plugin_id', event.get('[@metadata][dead_letter_queue][plugin_id]'))
  event.set('original', original_event.to_json)
  [event]
end
