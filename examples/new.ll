declare void @GC_init()
declare i8* @GC_malloc(i64)
declare void @llvm.memset.p0i8.i64(i8* nocapture, i8, i64, i32, i1)
declare i32 @putchar(i32)
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
define double @"A#hi"(%"A"* %self, double %x) {
  %reg1 = fadd double %x, 65.0
  %reg2 = fptosi double %reg1 to i32
  %reg3 = call i32 @putchar(i32 %reg2)
  %reg4 = sitofp i32 %reg3 to double
  ret double 0.0
}
define i32 @main() {
  call void @GC_init()
  %reg5 = call %"A"* @"A.new"()
  %reg6 = call double @"A#hi"(%"A"* %reg5, double 0.0)
  ret i32 0
}
