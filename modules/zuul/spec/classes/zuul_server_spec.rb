require 'spec_helper'

test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8', '9'],
    }
  ]
}

describe 'zuul::server' do
  on_supported_os(test_on).each do |os, facts|
    context "On #{os} do" do
      let(:facts) {
        facts.merge({
          :site => 'eqiad',
          :initsystem => 'systemd',
        })
      }
      let(:params) { {
        :gerrit_server => 'review.example.org',
        :gerrit_user => 'ci-bot',
        :gearman_server => '127.0.0.1',
        :gearman_server_start => true,
        :url_pattern => 'https://ci.example.org/job/{job.name}',
      } }
      it "should compile" do
        should contain_file('/etc/zuul/zuul-server.conf')
          .without_content(/\[merger\]/)
          .without_content(/^\[connection smtp\]$/)
      end

      context 'when email_server is set' do
        let(:params) {
          super().merge({ :email_server => 'mx01.example.org' })
        }
        it "should have have a smtp connection defined" do
          should contain_file('/etc/zuul/zuul-server.conf')
            .with_content(/^\[connection smtp\]$/)
            .with_content(/^server=mx01\.example\.org$/)
        end
      end
    end
  end
end
