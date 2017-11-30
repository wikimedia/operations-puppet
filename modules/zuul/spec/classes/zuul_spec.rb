require 'spec_helper'

test_on = {
  supported_os: [
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['8', '9'],
    }
  ]
}

describe 'zuul' do
  on_supported_os(test_on).each do |os, facts|
    context "On #{os}" do
      let(:facts) { facts }
      context "on production" do
        let(:node_params) {{realm: 'production', site: 'test'}}
        it { should compile }
      end
      context "on labs" do
        let(:node_params) {{realm: 'labs', site: 'test'}}
        it { should compile }
      end
    end
  end
end
