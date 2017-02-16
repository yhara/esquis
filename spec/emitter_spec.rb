require 'spec_helper'

describe "ll emitter:" do
  def to_ll(src)
    ast = Esquis::Parser.new.parse(src)
    ast.to_ll_str(without_header: true)
  end

  describe "extern" do
    it "should add the body to ll" do
      ll = to_ll(<<~EOD)
        extern i32 putchar(i32);
      EOD
      expect(ll).to eq(<<~EOD)
        declare i32 @putchar(i32)
        define i32 @main() {
          call void @GC_init()
          ret i32 0
        }
      EOD
    end
  end

  describe "main stmts" do
    it "should be the body of @main" do
      ll = to_ll(<<~EOD)
        extern i32 putchar(i32);
        putchar(65);
      EOD
      expect(ll).to eq(<<~EOD)
        declare i32 @putchar(i32)
        define i32 @main() {
          call void @GC_init()
          %reg1 = fptosi double 65.0 to i32
          %reg2 = call i32 @putchar(i32 %reg1)
          %reg3 = sitofp i32 %reg2 to double
          ret i32 0
        }
      EOD
    end
  end

  describe "class definition" do
    it "should deifne a struct type" do
      ll = to_ll(<<~EOD)
        class A end
      EOD
      expect(ll).to eq(<<~EOD)
        %"A" = type { i32 }
        define %"A"* @"A.new"() {
          %size = ptrtoint %"A"* getelementptr (%"A", %"A"* null, i32 1) to i64
          %raw_addr = call i8* @GC_malloc(i64 %size)
          %addr = bitcast i8* %raw_addr to %"A"*

          call void @llvm.memset.p0i8.i64(i8* %raw_addr, i8 0, i64 %size, i32 4, i1 false)

          %id_addr = getelementptr inbounds %"A", %"A"* %addr, i32 0, i32 0
          store i32 1, i32* %id_addr

          ret %"A"* %addr
        }
        define i32 @main() {
          call void @GC_init()
          ret i32 0
        }
      EOD
    end
  end

  describe "func definition" do
    it "should define a function" do
      ll = to_ll(<<~EOD)
        def foo(x: Float, y: Float) -> Float { return x; }
        foo(123, 456);
      EOD
      expect(ll).to eq(<<~EOD)
        define double @foo(double %x, double %y) {
          ret double %x
          ret double 0.0
        }
        define i32 @main() {
          call void @GC_init()
          %reg1 = call double @foo(double 123.0, double 456.0)
          ret i32 0
        }
      EOD
    end
  end

  describe "if stmt" do
    it "true case" do
      ll = to_ll(<<~EOD)
        extern i32 putchar(i32);
        if (1 < 2) {
          putchar(65);
        }
      EOD
      expect(ll).to eq(<<~EOD)
        declare i32 @putchar(i32)
        define i32 @main() {
          call void @GC_init()
          %reg1 = fcmp olt double 1.0, 2.0
          br i1 %reg1, label %Then1, label %EndIf1
        Then1:
          %reg2 = fptosi double 65.0 to i32
          %reg3 = call i32 @putchar(i32 %reg2)
          %reg4 = sitofp i32 %reg3 to double
          br label %EndIf1
        EndIf1:
          ret i32 0
        }
      EOD
    end
  end

  describe "for stmt" do
    it "should expand into loop" do
      ll = to_ll(<<~EOD)
        extern i32 putchar(i32);
        for (x; 65 ... 70 ; 2) {
          putchar(x);
        }
      EOD
      expect(ll).to eq(<<~EOD)
        declare i32 @putchar(i32)
        define i32 @main() {
          call void @GC_init()
          br label %For1
        For1:
          br label %Loop1
        Loop1:
          %x = phi double [65.0, %For1], [%fori1, %ForInc1]
          %forc1 = fcmp oge double %x, 70.0
          br i1 %forc1, label %EndFor1, label %ForBody1
        ForBody1:
          %reg1 = fptosi double %x to i32
          %reg2 = call i32 @putchar(i32 %reg1)
          %reg3 = sitofp i32 %reg2 to double
          br label %ForInc1
        ForInc1:
          %fori1 = fadd double %x, 2.0
          br label %Loop1
        EndFor1:
          ret i32 0
        }
      EOD
    end
  end

  describe "binary expr" do
    describe "`+`" do
      it "should conveted to add" do
        ll = to_ll(<<~EOD)
          extern i32 putchar(i32);
          putchar(60 + 5);
        EOD
        expect(ll).to eq(<<~EOD)
          declare i32 @putchar(i32)
          define i32 @main() {
            call void @GC_init()
            %reg1 = fadd double 60.0, 5.0
            %reg2 = fptosi double %reg1 to i32
            %reg3 = call i32 @putchar(i32 %reg2)
            %reg4 = sitofp i32 %reg3 to double
            ret i32 0
          }
        EOD
      end
    end
  end

  describe "unary expr" do
    describe "-" do
      it "should flip the sign" do
        ll = to_ll(<<~EOD)
          def foo(x: Float) -> Float { return -x; }
          foo(3);
        EOD
        expect(ll).to eq(<<~EOD)
          define double @foo(double %x) {
            %reg1 = fsub double 0.0, %x
            ret double %reg1
            ret double 0.0
          }
          define i32 @main() {
            call void @GC_init()
            %reg2 = call double @foo(double 3.0)
            ret i32 0
          }
        EOD
      end
    end
  end
end
