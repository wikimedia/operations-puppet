# frozen_string_literal: true

require_relative '../../../../rake_modules/spec_helper'

describe 'standard' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      it { is_expected.to compile.with_all_deps }
    end
  end
end
