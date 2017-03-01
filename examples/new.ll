declare i32 @printf(i8*, ...)
;declare i32 @putchar(i32)

@putd_tmpl = private unnamed_addr constant [3 x i8] c"%d\00"
define void @putd(i32 %num) {
  %putd1 = getelementptr inbounds [3 x i8], [3 x i8]* @putd_tmpl, i32 0, i32 0
  call i32 (i8*, ...) @printf(i8* %putd1, i32 %num)
  ret void
}

;define void @putc(i32 %c) {
;  call i32 @putchar(i32 %c)
;  ret void
;}
declare void @GC_init()
declare i8* @GC_malloc(i64)
declare void @llvm.memset.p0i8.i64(i8* nocapture, i8, i64, i32, i1)
declare i32 @putchar(i32)
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
define double @"A#x"(%"A"* %self) {
  %reg1 = getelementptr inbounds %"A", %"A"* %self, i32 0, i32 1
  %reg2 = load double, double* %reg1
  ret double %reg2
  ret double 0.0
}
define void @"A#initialize"(%"A"* %self, double %"@x") {
  %ivar1_addr = getelementptr inbounds %"A", %"A"* %self, i32 0, i32 1
  store double %"@x", double* %ivar1_addr

  ret void 
}
define i32 @main() {
  call void @GC_init()
  %reg3 = call %"A"* @"A.new"(double 65.0)
  %reg4 = call double @"A#x"(%"A"* %reg3)
  %reg5 = fptosi double %reg4 to i32
  %reg6 = call i32 @putchar(i32 %reg5)
  %reg7 = sitofp i32 %reg6 to double
  ret i32 0
}
