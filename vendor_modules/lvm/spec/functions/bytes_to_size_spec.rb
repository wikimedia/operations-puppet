# frozen_string_literal: true

require 'spec_helper'

describe 'lvm::bytes_to_size' do
  context 'with incorrect parameters' do
    it 'fails' do
      expect(subject).to run.with_params('foo').and_raise_error(
        ArgumentError,
        %r{expects a Numeric value},
      )
    end
  end

  context 'with lower case parameters' do
    it 'returns the correct values' do # rubocop:disable RSpec/MultipleExpectations
      expect(subject).to run.with_params(1024).and_return('1k')
      expect(subject).to run.with_params(1_048_576).and_return('1m')
      expect(subject).to run.with_params(1_073_741_824).and_return('1g')
      expect(subject).to run.with_params(1_099_511_627_776).and_return('1t')
      expect(subject).to run.with_params(1.12589991e15).and_return('1.0p')
      expect(subject).to run.with_params(1.1529215e18).and_return('1.0e')
      expect(subject).to run.with_params(214_748_364_800).and_return('200g')
      expect(subject).to run.with_params(1536.0).and_return('1.5k')
    end
  end
end
