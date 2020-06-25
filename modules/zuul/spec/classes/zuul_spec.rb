require 'spec_helper'

test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8', '10'],
    }
  ]
}

describe 'zuul' do
  on_supported_os(test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts }
      let(:pre_condition) {
        "define scap::target($deploy_user) {}"
      }
      context "on production" do
        let(:node_params) {{realm: 'production'}}
        it { should compile }
      end
      context "on labs" do
        let(:node_params) {{realm: 'labs'}}
        it { should compile }
      end
    end
  end
end
