# frozen_string_literal: true

require_relative '../../../../rake_modules/spec_helper'

describe 'package_builder::pbuilder_base' do
  on_supported_os(WMFConfig.test_on).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      let(:title) { 'foobar' }

      describe 'test with default settings' do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_exec('cowbuilder_init_stretch-amd64')
            .with_command(/(?!--extrapackages)/)
        end
      end
      describe 'Change Defaults' do
        context 'extra_packages' do
          let(:params) { {extra_packages: ['foo', 'bar']} }

          it { is_expected.to compile.with_all_deps }
          it do
            is_expected.to contain_exec('cowbuilder_init_stretch-amd64')
              .with_command(/--extrapackages "foo bar"/)
          end
        end
      end
    end
  end
end
