require 'spec_helper'

describe "Esquis" do
  def to_ll(src)
    ast = Esquis::Parser.new.parse(src)
    ast.to_ll_str
  end

  context "syntax" do
    it "should check duplicated toplevel func" do
      expect {
        to_ll(<<~EOD)
          extern i32 putchar(i32);
          def putchar(x: Float, y: Float) -> Float { return x; }
        EOD
      }.to raise_error(Esquis::Ast::DuplicatedDefinition)
    end

    it "should check duplicated param names" do
      expect {
        to_ll(<<~EOD)
          def putchar(x: Float, x: Float) -> Float { return x; }
        EOD
      }.to raise_error(Esquis::Ast::DuplicatedParamName)
    end

    it "should check return in main" do
      expect {
        to_ll(<<~EOD)
          return 1;
        EOD
      }.to raise_error(Esquis::Ast::MisplacedReturn)
    end
  end

  context "typing" do
    it "should check arity when calling toplevel func" do
      expect {
        to_ll(<<~EOD)
          def foo(x: Int) -> Int { 1; }
          foo(1, 2);
        EOD
      }.to raise_error(Esquis::Ast::ArityMismatch)
    end

    it "should check arg types when calling toplevel func"

    it "should check arity of method call"
    it "should check arg types of method call"

    it "should check condition of if-stmt is Bool" do
      expect {
        to_ll(<<~EOD)
          if (1) { 2; }
        EOD
      }.to raise_error(Esquis::Ast::TypeMismatch)

      expect {
        to_ll(<<~EOD)
          if (1 == 1) { 2; }
        EOD
      }.not_to raise_error
    end
  end
end
