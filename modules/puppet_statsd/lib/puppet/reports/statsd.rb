# Puppet StatsD reporter
# Sends timing measurements for Puppet runs to StatsD
require 'puppet'
require 'yaml'
require 'erb'

Puppet::Reports.register_report(:statsd) do
    desc <<-DESC
      Send Puppet metrics to StatsD
    DESC

    def load_config
        config_file = File.join Puppet.settings[:confdir], 'statsd.yaml'
        raise Puppet::ParseError, "#{config_file} is missing" unless File.exists? config_file
        YAML.load_file(config_file)
    end

    def process
        config = load_config
        hostname = host
        Puppet.notice "Sending metrics for #{host} to "\
            "#{config[:statsd_host]}:#{config[:statsd_port]}.."

        socket = UDPSocket.new
        metrics['time'].values.each do |metric, description, value|
            value = (value * 1000).round  # Convert fractional seconds to whole miliseconds
            name = ERB.new(config[:metric_format]).result(binding)
            socket.send("#{name}:#{value}|ms", 0, config[:statsd_host], config[:statsd_port])
        end
        socket.close
    end
end
