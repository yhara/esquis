require 'spec_helper'

describe "Esquis" do
  def to_ll(src)
    Esquis::Ast.reset
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
    context "method definition" do
      it "should check return type" do
        expect {
          to_ll(<<~EOD)
            class A
              def foo() -> Float {
                1 == 2;
              }
            end
          EOD
        }.to raise_error(Esquis::Ast::TypeMismatch)
      end

      it "should pass recursive method" do
        expect {
          to_ll(<<~EOD)
            class A
              def foo(x: Float) -> Float { A.new().foo(x); }
            end
          EOD
        }.not_to raise_error
      end
    end

    context "method/function call" do
      it "should check arity when calling toplevel func" do
        expect {
          to_ll(<<~EOD)
            def foo(x: Float) -> Float { 1; }
            foo(1, 2);
          EOD
        }.to raise_error(Esquis::Ast::ArityMismatch)
      end

      it "should check arg types when calling toplevel func" do
        expect {
          to_ll(<<~EOD)
            def foo(x: Float) -> Float { 1; }
            foo(1 == 2);
          EOD
        }.to raise_error(Esquis::Ast::TypeMismatch)
      end

      it "should pass recursive toplevel func" do
        expect {
          to_ll(<<~EOD)
            def foo(x: Float) -> Float { foo(x); }
          EOD
        }.not_to raise_error
      end

      it "should check arity of new" do
        expect {
          to_ll(<<~EOD)
            class A
              def initialize() { 1; }
            end
            A.new(1);
          EOD
        }.to raise_error(Esquis::Ast::ArityMismatch)
      end

      it "should check arg types of new" do
        expect {
          to_ll(<<~EOD)
            class A
              def initialize(x: Float) { 1; }
            end
            A.new(1 == 1);
          EOD
        }.to raise_error(Esquis::Ast::TypeMismatch)
      end

      it "should check arity of method call" do
        expect {
          to_ll(<<~EOD)
            class A
              def foo() -> Float { 1; }
            end
            A.new().foo(1);
          EOD
        }.to raise_error(Esquis::Ast::ArityMismatch)
      end

      it "should check arg types of method call" do
        expect {
          to_ll(<<~EOD)
            class A
              def foo(x: Float) -> Float { 1; }
            end
            A.new().foo(1 == 1);
          EOD
        }.to raise_error(Esquis::Ast::TypeMismatch)
      end
    end

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
