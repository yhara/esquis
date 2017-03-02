require 'spec_helper'

describe Esquis do
  def run(src)
    Esquis::Ast.reset
    return Esquis.run(src, capture: true)
  end

  it 'should parse example program' do
    expect {
      ast = Esquis::Parser.new.parse(File.read("#{__dir__}/../examples/mandel.es"))
      ast.to_ll_str
    }.not_to raise_error
  end

  describe '.run' do
    it 'should run esquis program (with llc)' do
      out = run(<<~EOD)
        extern i32 putchar(i32)
        putchar(65)
      EOD
      expect(out).to eq("A")
    end
  end

  describe 'programs' do
    it 'defclass' do
      src = <<~EOD
        extern i32 putchar(i32)
        class A
          def hi(x: Float) -> Void do putchar(x + 65) end
        end
        A.new().hi(0)
      EOD
      expect(run(src)).to eq("A")
    end

    it 'defun' do
      src = <<~EOD
        extern i32 putchar(i32)
        def add(x: Float, y: Float) -> Float do return x + y end
        putchar(add(60, 5))
      EOD
      expect(run(src)).to eq("A")
    end

    it '+' do
      src = "extern i32 putchar(i32) putchar(60 + 5)"
      expect(run(src)).to eq("A")
    end

    it '-' do
      src = "extern i32 putchar(i32) putchar(70 - 5)"
      expect(run(src)).to eq("A")
    end

    it '*' do
      src = "extern i32 putchar(i32) putchar(13 * 5)"
      expect(run(src)).to eq("A")
    end

    it '/' do
      src = "extern i32 putchar(i32) putchar(157 / 2.41)"
      expect(run(src)).to eq("A")
    end

    it '==' do
      src = "extern i32 putchar(i32) if (1 == 1) do putchar(65) end"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32) if (1 == 2) do putchar(65) end"
      expect(run(src)).to eq("")
    end

    it '>' do
      src = "extern i32 putchar(i32) if (2 > 1) do putchar(65) end"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32) if (1 > 2) do putchar(65) end"
      expect(run(src)).to eq("")
    end

    it '>=' do
      src = "extern i32 putchar(i32) if (1 >= 1) do putchar(65) end"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32) if (1 >= 2) do putchar(65) end"
      expect(run(src)).to eq("")
    end

    it '<' do
      src = "extern i32 putchar(i32) if (1 < 2) do putchar(65) end"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32) if (2 < 1) do putchar(65) end"
      expect(run(src)).to eq("")
    end

    it '<=' do
      src = "extern i32 putchar(i32) if (1 <= 1) do putchar(65) end"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32) if (2 <= 1) do putchar(65) end"
      expect(run(src)).to eq("")
    end

    it '!=' do
      src = "extern i32 putchar(i32) if (1 != 2) do putchar(65) end"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32) if (1 != 1) do putchar(65) end"
      expect(run(src)).to eq("")
    end

    it '&&' do
      src = "extern i32 putchar(i32) if (1 == 1 && 2 == 2) do putchar(65) end"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32) if (1 == 1 && 2 == 0) do putchar(65) end"
      expect(run(src)).to eq("")
    end

    it '||' do
      src = "extern i32 putchar(i32) if (1 == 0 || 2 == 2) do putchar(65) end"
      expect(run(src)).to eq("A")
      src = "extern i32 putchar(i32) if (1 == 0 || 2 == 0) do putchar(65) end"
      expect(run(src)).to eq("")
    end

    it 'unary -' do
      src = "extern i32 putchar(i32) putchar(-(-65))"
      expect(run(src)).to eq("A")
    end

    it 'for' do
      src = <<-EOD
        extern i32 putchar(i32)
        for (x: Int; 65 ... 70 ; 2) do
          putchar(x)
        end
      EOD
      expect(run(src)).to eq("ACE")
    end

    context 'ivar' do
      it 'reference with name' do
        src = <<~EOD
          extern i32 putchar(i32)
          class A
            def initialize(@x: Float) do end
            def foo() -> Float do return @x end
          end
          putchar(A.new(65).foo())
        EOD
        expect(run(src)).to eq("A")
      end

      it 'reference with accessor' do
        src = <<~EOD
          extern i32 putchar(i32)
          class A
            def initialize(@x: Float) do end
          end
          putchar(A.new(65).x)
        EOD
        expect(run(src)).to eq("A")
      end
    end
  end
end
