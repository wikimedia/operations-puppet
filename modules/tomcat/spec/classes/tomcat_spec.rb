# frozen_string_literal: true

require_relative '../../../../rake_modules/spec_helper'

describe 'tomcat' do
  on_supported_os(WMFConfig.test_on(10, 10)).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      # let(:pre_condition) do
      #  "class profile::base ( $notifications_enabled = 1 ){}
      #  include profile::base"
      # end
      describe 'test with default settings' do
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
