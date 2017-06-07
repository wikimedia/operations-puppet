#!/usr/bin/env ruby
require 'English'
require 'optparse'
require 'net/http'
require 'facter'

PATH_ROOT = '/usr/local/bin/'

# default values
args = {
  host: Facter.value(:fqdn),
  command: PATH_ROOT + 'pool',
  pool: true,
  depool: false,
  lvs_uri: [],
  pool_name: nil,
  pool_subject: '',
  interval: 1,
  wait: 9,
  cycles: 3
}

# parse the command-line arguments
OptionParser.new do |opts|
  opts.banner = "Usage: pooler-loop [options] [service]"
  opts.on('-p', '--pool', '(Re)pool the host') do
    args[:command] = PATH_ROOT + 'pool'
    args[:pool] = true
    args[:depool] = false
  end
  opts.on('-d', '--depool', 'Depool the host') do
    args[:command] = PATH_ROOT + 'depool'
    args[:depool] = true
    args[:pool] = false
  end
  opts.on('-l', '--lvs-ips IP1,IP2', 'The LVS IPs to contact') do |ips|
    args[:lvs_uris] = ips.split(/,\s*/).map{ |ip| [ip, 9090]}
  end
  opts.on('-P', '--pool-name POOL', 'The pool name to use') do |pool|
    args[:pool_name] = pool
  end
  opts.on('-i', '--interval INTERVAL', Float,
          'The check interval, in seconds') do |i|
    args[:interval] = i
  end
  opts.on('-w', '--wait TIMES', Integer, 'The number of intervals to wait ' +
      'before', 're-issuing the (de)pool command') do |w|
    args[:wait] = w
  end
  opts.on('-c', '--cycles N', Integer, 'The number of times to repeat',
          'the process for') do |n|
    args[:cycles] = n
  end
  opts.on_tail('-h', '--help', 'Show this text and exit') do
    puts opts
    exit
  end
end.parse!

args[:pool_subject] = ARGV.shift || ''

unless args[:pool_name]
  puts 'You have to specify the pool name! Use pooler-loop -h for help'
  exit 1
end

class PybalError < StandardError
end

def check_pooled_state(ip, port, pool, host, want_pooled)
  # Manage down or unresponsive pybals
  http = Net::HTTP.new(ip, port)
  http.open_timeout = 1
  http.read_timeout = 2

  begin
    resp = http.start do |http|
      http.get "/pools/#{pool}/#{host}"
    end
  rescue Timeout::Error
    # If pybal is down, don't care about it
    return true
  end
  # ignore 404s
  # rubocop:disable Style/CaseEquality
  return true unless resp === Net::HTTPSuccess
  # rubocop:enable Style/CaseEquality
  enabled, active, pooled = resp.body.strip.split '/'
  if want_pooled
    # A pooled server must be enabled/up/pooled
    # anything else is not ok
    if enabled != 'enabled'
      raise PybalError, "#{host} not logically pooled, lb #{ip}"
    elsif active != 'up'
      raise PybalError, "The service is not up on #{host}, lb #{ip}"
    elsif pooled != 'pooled'
      raise PybalError, "Service not pooled"
    end
  else
    # A disabled server should be disabled/{up,down}/not pooled
    if enabled == 'enabled'
      raise PybalError, "#{host} is still logically pooled, lb #{ip}"
    elsif pooled == 'pooled'
      raise PybalError, "#{host} is still pooled, maybe too many depooled? lb #{ip}"
    end
  end
end

# do the whole procedure args[:cycles] times
(1..args[:cycles]).each do
  # try to (de)pool the host we are on
  `#{args[:command]} "#{args[:pool_subject]}"`

  # If the script exited with status !=0, we surely had an error; retry directly.
  if $CHILD_STATUS.exitstatus != 0
    sleep args[:interval]
    next
  end
  # check at most args[:wait] times each args[:interval]
  # seconds with the LVS server to confirm the host is in
  # the desired state
  (1..args[:wait]).each do
    sleep args[:interval]
    begin
      args[:lvs_uris].each do |uri|
        ip, port = uri
        check_pooled_state(ip, port, args[:pool_name], args[:host], args[:pool])
      end
      exit 0
    rescue PybalError => e
      puts "Found an error: #{e.message}"
    end
  end
end

exit 2
