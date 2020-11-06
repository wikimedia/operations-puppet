require_relative '../../../../rake_modules/spec_helper'

describe 'bacula::client::job', :type => :define do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:title) { 'something' }
      let(:params) { {
        :fileset      => 'root',
        :jobdefaults  => 'testdefaults',
      }
      }
    end
  end
end
