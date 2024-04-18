require_relative '../../../../rake_modules/spec_helper'

describe 'zuul::server' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "On #{os} do" do
      let(:facts) { facts }
      let(:pre_condition) {
          "define scap::target($deploy_user) {}"
      }
      let(:params) { {
        :gerrit_server => 'review.example.org',
        :gerrit_user => 'ci-bot',
        :gearman_server => 'contint.wikimedia.org',
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
