# SPDX-License-Identifier: Apache-2.0
# Custom filter that populates a 'streams' top-level key in the logstash event with
# the format Loki expects.
# https://github.com/grafana/loki/blob/master/docs/api.md#post-lokiapiv1push

require 'json'

def register(params)
  @event_type = params["type"]
end

def filter(event)
  # event timestamp to nanoseconds
  ts = (event.get('@timestamp').to_i * 1e9).to_s.split('.')[0]

  case @event_type
  when 'alert'
    stream = { :type => 'alert', :host => event.get('host')}
    values = [[ts, "#{event.get('icinga_state')} -- #{event.get('icinga_check_descr')}: #{event.get('icinga_message')}"]]
  when 'sal'
    stream = { :type => 'sal', :project => event['project'] }
    values = [[ts, "#{event.get('nick')}: #{event.get('message')}"]]
  when 'deploy'
    stream = { :type => 'deploy' }
    values = [[ts, "#{event.get('user')}: #{event.get('message')}"]]
  else
    # do nothing
    return [event]
  end

  event.set('streams', [{ :stream => stream, :values => values }])
  [event]
end
