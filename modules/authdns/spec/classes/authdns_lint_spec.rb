require 'integration_helper'
require 'pry'

describe 'authdns::config' do

    context do
        let(:facts) { {
            :lsbdistrelease => '8.6',
            :lsbdistid => 'Debian',
            :operatingsystem => 'Debian',
        } }

        hiera = Hiera.new(
            :config => 'spec/fixtures/hiera.yaml'
        )
        let(:params) { {
            :lvs_services => hiera.lookup('lvs::configuration::lvs_services', nil, {}),
            :discovery_services => hiera.lookup('discovery::services', nil, {}),
        } }

        it {
            should compile
            catalogue.resources.each { |res|
                next unless res.type == 'File'
                next unless res.include? 'content'
                puts '-' * 72
                puts res['path']
                puts '=' * 72
                puts res['content']
                puts '=' * 72
                # Fixme rewrite path to some temp dir
            }
            binding.pry unless ENV['JENKINS_URL']
        }
    end
end
