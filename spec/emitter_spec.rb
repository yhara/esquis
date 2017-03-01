require 'spec_helper'

describe "ll emitter:" do
  def to_ll(src)
    Esquis::Ast.reset
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
        class A
          def initialize(@x: Float) { }
        end
      EOD
      expect(ll[/^%"A"(.*?)^\}\n/m]).to eq(<<~EOD)
        %"A" = type { i32, double }
        define %"A"* @"A.new"(double %"@x") {
          %size = ptrtoint %"A"* getelementptr (%"A", %"A"* null, i32 1) to i64
          %raw_addr = call i8* @GC_malloc(i64 %size)
          %addr = bitcast i8* %raw_addr to %"A"*

          call void @llvm.memset.p0i8.i64(i8* %raw_addr, i8 0, i64 %size, i32 4, i1 false)

          %id_addr = getelementptr inbounds %"A", %"A"* %addr, i32 0, i32 0
          store i32 1, i32* %id_addr
          call void @"A#initialize"(%"A"* %addr, double %"@x")
          ret %"A"* %addr
        }
      EOD
    end
  end

  describe "initialize" do
    it "should store ivar values" do
      ll = to_ll(<<~EOD)
        class A
          def initialize(@x: Float) {
            1 + 1;
          }
        end
        A.new(2);
      EOD
      expect(ll[/^define void @"A#initialize"(.*?)^\}\n/m]).to eq(<<~EOD)
        define void @"A#initialize"(%"A"* %self, double %"@x") {
          %ivar1_addr = getelementptr inbounds %"A", %"A"* %self, i32 0, i32 1
          store double %"@x", double* %ivar1_addr

          %reg3 = fadd double 1.0, 1.0
          ret void 
        }
      EOD
      expect(ll[/^define i32 @main(.*?)^}\n/m]).to eq(<<~EOD)
        define i32 @main() {
          call void @GC_init()
          %reg4 = call %"A"* @"A.new"(double 2.0)
          ret i32 0
        }
      EOD
    end
  end

  describe "instance creation" do
    it "should call .new" do
      ll = to_ll(<<~EOD)
        class A end
        A.new();
      EOD
      expect(ll[/^define i32 @main(.*?)^}\n/m]).to eq(<<~EOD)
        define i32 @main() {
          call void @GC_init()
          %reg1 = call %"A"* @"A.new"()
          ret i32 0
        }
      EOD
    end
  end

  describe "method definition" do
    it "should define a function" do
      ll = to_ll(<<~EOD)
        class A
          def foo(x: Float) -> Float {
            return 123;
          }
        end
      EOD
      expect(ll).to include(<<~EOD)
        define double @"A#foo"(%"A"* %self, double %x) {
          ret double 123.0
          ret double 0.0
        }
      EOD
    end
  end

  describe "method call" do
    it "should call a function" do
      ll = to_ll(<<~EOD)
        class A
          def foo(x: Float) -> Float {
            return 123;
          }
        end
        A.new().foo(234);
      EOD
      expect(ll[/^define i32 @main(.*?)^}\n/m]).to eq(<<~EOD)
        define i32 @main() {
          call void @GC_init()
          %reg1 = call %"A"* @"A.new"()
          %reg2 = call double @"A#foo"(%"A"* %reg1, double 234.0)
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
        for (x: Float; 65 ... 70 ; 2) {
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
