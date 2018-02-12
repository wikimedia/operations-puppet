require 'uri'

# Minimal mock class for PuppetDB config
module Puppet::Util::Puppetdb
  class Config
    def server_urls
      [URI('http://puppetdb.puppetexplorer.io')]
    end
  end

  def self.config
    Puppet::Util::Puppetdb::Config.new
  end
end
