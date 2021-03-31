# frozen_string_literal: true

require_relative '../../../../rake_modules/spec_helper'

describe 'package_builder' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:pre_condition) { 'exec { "apt-get update": command => "/bin/true"}' }

      describe 'test with default settings' do
        it { is_expected.to compile.with_all_deps }
      end
      describe 'Change Defaults' do
        context 'extra_packages' do
          let(:params) { {extra_packages: {'buster' => ['foobar']}} }

          it { is_expected.to compile.with_all_deps }
        end
      end
    end
  end
end
