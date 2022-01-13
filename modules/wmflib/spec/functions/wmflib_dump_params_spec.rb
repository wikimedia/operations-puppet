require_relative '../../../../rake_modules/spec_helper'

describe 'wmflib::dump_params' do
  it 'exists' do
    is_expected.not_to be_nil
  end

  it 'requires an argument' do
    is_expected.to run.and_return({})
  end
  describe 'mock resource' do
    before do
      allow(scope).to receive(:resource).and_return({foo: 'foo', bar: 'bar'})
    end
    it 'convert symbols to strings' do
      is_expected.to run.and_return({'foo' => 'foo', 'bar' => 'bar'})
    end
    it 'filter bar' do
      is_expected.to run.with_params(['bar']).and_return({'foo' => 'foo'})
    end
    it 'filter foo' do
      is_expected.to run.with_params(['foo']).and_return({'bar' => 'bar'})
    end
  end
end
