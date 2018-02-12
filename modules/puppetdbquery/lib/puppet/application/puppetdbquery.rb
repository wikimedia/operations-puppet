require 'puppet/application/face_base'

class Puppet::Application::Puppetdbquery < Puppet::Application::FaceBase
  def self.setting
    use_ssl = true
    begin
      require 'puppet'
      require 'puppet/util/puppetdb'
      PuppetDB::Connection.check_version
      uri = URI(Puppet::Util::Puppetdb.config.server_urls.first)
      host = uri.host
      port = uri.port
    rescue Exception => e
      Puppet.debug(e.message)
      host = 'puppetdb'
      port = 8081
    end

    Puppet.debug(host)
    Puppet.debug(port)
    Puppet.debug("use_ssl=#{use_ssl}")

    { :host => host,
      :port => port,
      :use_ssl => use_ssl
    }
  end
end
