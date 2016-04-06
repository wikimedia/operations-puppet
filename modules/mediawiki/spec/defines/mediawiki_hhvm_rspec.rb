require 'spec_helper'

describe 'mediawiki::hhvm', :type => :class do
  let(:facts) { { :lsbdistrelease => 'ubuntu',
                  :lsbdistid      => 'trusty',
                  :fqdn => 'host.example.net'
  } }
  let(:hiera_data) { {
    :ganglia_clusters => {
      :appserver => {
        :name => "Application servers",
        :id   => 11,
        :sites => {
          :eqiad => [],
          :codfw => [],
        }
      }
    }
  } }

  it 'should ensure that HHVM config file is created' do
    should contain_file('/etc/hhvm/fcgi.ini').with({ 'ensure' => 'present' })
  end

end
