require 'spec_helper'

describe "the hash_deselect_re function" do
  it "should exist" do
    Puppet::Parser::Functions.function("hash_deselect_re").should == "function_hash_deselect_re"
  end

  it "should raise a ParseError if there are less than 2 arguments" do
    ->{ scope.function_hash_deselect_re(['a']) }.should(raise_error(Puppet::ParseError))
  end

  it "should raise a ParseError if there are more than 2 arguments" do
    ->{ scope.function_hash_deselect_re(['a', 'b', 'c']) }.should(raise_error(Puppet::ParseError))
  end

  it "should select the right keys (simple)" do
    result = scope.function_hash_deselect_re(['^a', {'abc' => 1, 'def' => 2, 'asdf' => 3}])
    result.should(eq({'def' => 2}))
  end

  it "should select the right keys (neg lookahead)" do
    result = scope.function_hash_deselect_re(['^(?!a)', {'abc' => 1, 'def' => 2, 'asdf' => 3}])
    result.should(eq({'abc' => 1, 'asdf' => 3}))
  end
end
