declare i32 @printf(i8*, ...)
;declare i32 @putchar(i32)

@putd_tmpl = private unnamed_addr constant [3 x i8] c"%d\00"
define void @putd(i32 %num) {
  %putd1 = getelementptr inbounds [3 x i8], [3 x i8]* @putd_tmpl, i32 0, i32 0
  call i32 (i8*, ...) @printf(i8* %putd1, i32 %num)
  ret void
}

@putf_tmpl = private unnamed_addr constant [3 x i8] c"%f\00"
define void @putf(double %num) {
  %putf1 = getelementptr inbounds [3 x i8], [3 x i8]* @putf_tmpl, i32 0, i32 0
  call i32 (i8*, ...) @printf(i8* %putf1, double %num)
  ret void
}

;define void @putc(i32 %c) {
;  call i32 @putchar(i32 %c)
;  ret void
;}
declare void @GC_init()
declare i8* @GC_malloc(i64)
declare void @llvm.memset.p0i8.i64(i8* nocapture, i8, i64, i32, i1)
@"IMAGE_WIDTH" = internal global double 0.0
@"IMAGE_HEIGHT" = internal global double 0.0
@"IMAGE_DEPTH" = internal global double 0.0
@"EPS" = internal global double 0.0
@"MAX_REF" = internal global double 0.0
@"LIGHT" = internal global %"Vec"* null
@"PLANE" = internal global %"Plane"* null
@"T" = internal global double 0.0
@"SPHERE1" = internal global %"Sphere"* null
@"SPHERE2" = internal global %"Sphere"* null
@"SPHERE3" = internal global %"Sphere"* null
declare i32 @putchar(i32)
declare double @sqrt(double)
declare double @fabs(double)
declare double @sin(double)
declare double @cos(double)
define double @"clamp"(double %t, double %min, double %max) {
  %reg25 = fcmp olt double %t, %min
  br i1 %reg25, label %Then1, label %Else1
Then1:
  br label %ThenEnd1
ThenEnd1:
  br label %EndIf1
Else1:
  %reg26 = fcmp ogt double %t, %max
  br i1 %reg26, label %Then2, label %Else2
Then2:
  br label %ThenEnd2
ThenEnd2:
  br label %EndIf2
Else2:
  br label %ElseEnd2
ElseEnd2:
  br label %EndIf2
EndIf2:
  %reg27 = phi double [%max, %ThenEnd2], [%t, %ElseEnd2]
  br label %ElseEnd1
ElseEnd1:
  br label %EndIf1
EndIf1:
  %reg28 = phi double [%min, %ThenEnd1], [%reg27, %ElseEnd1]
  ret double %reg28
}
%"Vec" = type { i32, double, double, double }
define %"Vec"* @"Vec.new"(double %"@x", double %"@y", double %"@z") {
  %size = ptrtoint %"Vec"* getelementptr (%"Vec", %"Vec"* null, i32 1) to i64
  %raw_addr = call i8* @GC_malloc(i64 %size)
  %addr = bitcast i8* %raw_addr to %"Vec"*

  call void @llvm.memset.p0i8.i64(i8* %raw_addr, i8 0, i64 %size, i32 4, i1 false)

  %id_addr = getelementptr inbounds %"Vec", %"Vec"* %addr, i32 0, i32 0
  store i32 1, i32* %id_addr
  call void @"Vec#initialize"(%"Vec"* %addr, double %"@x", double %"@y", double %"@z")
  ret %"Vec"* %addr
}
define double @"Vec#x"(%"Vec"* %self) {
  %reg29 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 1
  %reg30 = load double, double* %reg29
  ret double %reg30
}
define double @"Vec#x="(%"Vec"* %self, double %value) {
  %reg31 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 1
  store double %value, double* %reg31
  ret double %value
}
define double @"Vec#y"(%"Vec"* %self) {
  %reg32 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 2
  %reg33 = load double, double* %reg32
  ret double %reg33
}
define double @"Vec#y="(%"Vec"* %self, double %value) {
  %reg34 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 2
  store double %value, double* %reg34
  ret double %value
}
define double @"Vec#z"(%"Vec"* %self) {
  %reg35 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 3
  %reg36 = load double, double* %reg35
  ret double %reg36
}
define double @"Vec#z="(%"Vec"* %self, double %value) {
  %reg37 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 3
  store double %value, double* %reg37
  ret double %value
}
define void @"Vec#initialize"(%"Vec"* %self, double %"@x", double %"@y", double %"@z") {
  %ivar1_addr = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 1
  store double %"@x", double* %ivar1_addr
  %ivar2_addr = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 2
  store double %"@y", double* %ivar2_addr
  %ivar3_addr = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 3
  store double %"@z", double* %ivar3_addr

  ret void
}
define %"Vec"* @"Vec#vadd"(%"Vec"* %self, %"Vec"* %b) {
  %reg38 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 1
  %reg39 = load double, double* %reg38
  %reg40 = call double @"Vec#x"(%"Vec"* %b)
  %reg41 = fadd double %reg39, %reg40
  %reg42 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 2
  %reg43 = load double, double* %reg42
  %reg44 = call double @"Vec#y"(%"Vec"* %b)
  %reg45 = fadd double %reg43, %reg44
  %reg46 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 3
  %reg47 = load double, double* %reg46
  %reg48 = call double @"Vec#z"(%"Vec"* %b)
  %reg49 = fadd double %reg47, %reg48
  %reg50 = call %"Vec"* @"Vec.new"(double %reg41, double %reg45, double %reg49)
  ret %"Vec"* %reg50
}
define %"Vec"* @"Vec#vsub"(%"Vec"* %self, %"Vec"* %b) {
  %reg51 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 1
  %reg52 = load double, double* %reg51
  %reg53 = call double @"Vec#x"(%"Vec"* %b)
  %reg54 = fsub double %reg52, %reg53
  %reg55 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 2
  %reg56 = load double, double* %reg55
  %reg57 = call double @"Vec#y"(%"Vec"* %b)
  %reg58 = fsub double %reg56, %reg57
  %reg59 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 3
  %reg60 = load double, double* %reg59
  %reg61 = call double @"Vec#z"(%"Vec"* %b)
  %reg62 = fsub double %reg60, %reg61
  %reg63 = call %"Vec"* @"Vec.new"(double %reg54, double %reg58, double %reg62)
  ret %"Vec"* %reg63
}
define %"Vec"* @"Vec#vmul"(%"Vec"* %self, double %t) {
  %reg64 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 1
  %reg65 = load double, double* %reg64
  %reg66 = fmul double %reg65, %t
  %reg67 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 2
  %reg68 = load double, double* %reg67
  %reg69 = fmul double %reg68, %t
  %reg70 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 3
  %reg71 = load double, double* %reg70
  %reg72 = fmul double %reg71, %t
  %reg73 = call %"Vec"* @"Vec.new"(double %reg66, double %reg69, double %reg72)
  ret %"Vec"* %reg73
}
define %"Vec"* @"Vec#vmulti"(%"Vec"* %self, %"Vec"* %b) {
  %reg74 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 1
  %reg75 = load double, double* %reg74
  %reg76 = call double @"Vec#x"(%"Vec"* %b)
  %reg77 = fmul double %reg75, %reg76
  %reg78 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 2
  %reg79 = load double, double* %reg78
  %reg80 = call double @"Vec#y"(%"Vec"* %b)
  %reg81 = fmul double %reg79, %reg80
  %reg82 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 3
  %reg83 = load double, double* %reg82
  %reg84 = call double @"Vec#z"(%"Vec"* %b)
  %reg85 = fmul double %reg83, %reg84
  %reg86 = call %"Vec"* @"Vec.new"(double %reg77, double %reg81, double %reg85)
  ret %"Vec"* %reg86
}
define double @"Vec#vdot"(%"Vec"* %self, %"Vec"* %b) {
  %reg87 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 1
  %reg88 = load double, double* %reg87
  %reg89 = call double @"Vec#x"(%"Vec"* %b)
  %reg90 = fmul double %reg88, %reg89
  %reg91 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 2
  %reg92 = load double, double* %reg91
  %reg93 = call double @"Vec#y"(%"Vec"* %b)
  %reg94 = fmul double %reg92, %reg93
  %reg95 = fadd double %reg90, %reg94
  %reg96 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 3
  %reg97 = load double, double* %reg96
  %reg98 = call double @"Vec#z"(%"Vec"* %b)
  %reg99 = fmul double %reg97, %reg98
  %reg100 = fadd double %reg95, %reg99
  ret double %reg100
}
define %"Vec"* @"Vec#vcross"(%"Vec"* %self, %"Vec"* %b) {
  %reg101 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 2
  %reg102 = load double, double* %reg101
  %reg103 = call double @"Vec#z"(%"Vec"* %b)
  %reg104 = fmul double %reg102, %reg103
  %reg105 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 3
  %reg106 = load double, double* %reg105
  %reg107 = call double @"Vec#y"(%"Vec"* %b)
  %reg108 = fmul double %reg106, %reg107
  %reg109 = fsub double %reg104, %reg108
  %reg110 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 3
  %reg111 = load double, double* %reg110
  %reg112 = call double @"Vec#x"(%"Vec"* %b)
  %reg113 = fmul double %reg111, %reg112
  %reg114 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 1
  %reg115 = load double, double* %reg114
  %reg116 = call double @"Vec#z"(%"Vec"* %b)
  %reg117 = fmul double %reg115, %reg116
  %reg118 = fsub double %reg113, %reg117
  %reg119 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 1
  %reg120 = load double, double* %reg119
  %reg121 = call double @"Vec#y"(%"Vec"* %b)
  %reg122 = fmul double %reg120, %reg121
  %reg123 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 2
  %reg124 = load double, double* %reg123
  %reg125 = call double @"Vec#x"(%"Vec"* %b)
  %reg126 = fmul double %reg124, %reg125
  %reg127 = fsub double %reg122, %reg126
  %reg128 = call %"Vec"* @"Vec.new"(double %reg109, double %reg118, double %reg127)
  ret %"Vec"* %reg128
}
define double @"Vec#vlength"(%"Vec"* %self) {
  %reg129 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 1
  %reg130 = load double, double* %reg129
  %reg131 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 1
  %reg132 = load double, double* %reg131
  %reg133 = fmul double %reg130, %reg132
  %reg134 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 2
  %reg135 = load double, double* %reg134
  %reg136 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 2
  %reg137 = load double, double* %reg136
  %reg138 = fmul double %reg135, %reg137
  %reg139 = fadd double %reg133, %reg138
  %reg140 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 3
  %reg141 = load double, double* %reg140
  %reg142 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 3
  %reg143 = load double, double* %reg142
  %reg144 = fmul double %reg141, %reg143
  %reg145 = fadd double %reg139, %reg144
  %reg146 = call double @"sqrt"(double %reg145)
  ret double %reg146
}
define %"Vec"* @"Vec#vnormalize!"(%"Vec"* %self) {
  %reg147 = call double @"Vec#vlength"(%"Vec"* %self)
  %"len" = bitcast double %reg147 to double
  %reg148 = fcmp ogt double %"len", 1.0e-17
  br i1 %reg148, label %Then3, label %Else3
Then3:
  %reg149 = fdiv double 1.0, %"len"
  %"r_len" = bitcast double %reg149 to double
  %reg150 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 1
  %reg151 = load double, double* %reg150
  %reg152 = fmul double %reg151, %"r_len"
  %reg153 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 1
  store double %reg152, double* %reg153
  %reg154 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 2
  %reg155 = load double, double* %reg154
  %reg156 = fmul double %reg155, %"r_len"
  %reg157 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 2
  store double %reg156, double* %reg157
  %reg158 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 3
  %reg159 = load double, double* %reg158
  %reg160 = fmul double %reg159, %"r_len"
  %reg161 = getelementptr inbounds %"Vec", %"Vec"* %self, i32 0, i32 3
  store double %reg160, double* %reg161
  br label %ThenEnd3
ThenEnd3:
  br label %EndIf3
Else3:
  br label %ElseEnd3
ElseEnd3:
  br label %EndIf3
EndIf3:
  ret %"Vec"* %self
}
define %"Vec"* @"Vec#reflect"(%"Vec"* %self, %"Vec"* %normal) {
  %reg163 = fsub double 0.0, 2.0
  %reg164 = call double @"Vec#vdot"(%"Vec"* %normal, %"Vec"* %self)
  %reg165 = fmul double %reg163, %reg164
  %reg166 = call %"Vec"* @"Vec#vmul"(%"Vec"* %normal, double %reg165)
  %reg167 = call %"Vec"* @"Vec#vadd"(%"Vec"* %self, %"Vec"* %reg166)
  ret %"Vec"* %reg167
}
%"Ray" = type { i32, %"Vec"*, %"Vec"* }
define %"Ray"* @"Ray.new"(%"Vec"* %"@origin", %"Vec"* %"@dir") {
  %size = ptrtoint %"Ray"* getelementptr (%"Ray", %"Ray"* null, i32 1) to i64
  %raw_addr = call i8* @GC_malloc(i64 %size)
  %addr = bitcast i8* %raw_addr to %"Ray"*

  call void @llvm.memset.p0i8.i64(i8* %raw_addr, i8 0, i64 %size, i32 4, i1 false)

  %id_addr = getelementptr inbounds %"Ray", %"Ray"* %addr, i32 0, i32 0
  store i32 2, i32* %id_addr
  call void @"Ray#initialize"(%"Ray"* %addr, %"Vec"* %"@origin", %"Vec"* %"@dir")
  ret %"Ray"* %addr
}
define %"Vec"* @"Ray#origin"(%"Ray"* %self) {
  %reg168 = getelementptr inbounds %"Ray", %"Ray"* %self, i32 0, i32 1
  %reg169 = load %"Vec"*, %"Vec"** %reg168
  ret %"Vec"* %reg169
}
define %"Vec"* @"Ray#origin="(%"Ray"* %self, %"Vec"* %value) {
  %reg170 = getelementptr inbounds %"Ray", %"Ray"* %self, i32 0, i32 1
  store %"Vec"* %value, %"Vec"** %reg170
  ret %"Vec"* %value
}
define %"Vec"* @"Ray#dir"(%"Ray"* %self) {
  %reg171 = getelementptr inbounds %"Ray", %"Ray"* %self, i32 0, i32 2
  %reg172 = load %"Vec"*, %"Vec"** %reg171
  ret %"Vec"* %reg172
}
define %"Vec"* @"Ray#dir="(%"Ray"* %self, %"Vec"* %value) {
  %reg173 = getelementptr inbounds %"Ray", %"Ray"* %self, i32 0, i32 2
  store %"Vec"* %value, %"Vec"** %reg173
  ret %"Vec"* %value
}
define void @"Ray#initialize"(%"Ray"* %self, %"Vec"* %"@origin", %"Vec"* %"@dir") {
  %ivar1_addr = getelementptr inbounds %"Ray", %"Ray"* %self, i32 0, i32 1
  store %"Vec"* %"@origin", %"Vec"** %ivar1_addr
  %ivar2_addr = getelementptr inbounds %"Ray", %"Ray"* %self, i32 0, i32 2
  store %"Vec"* %"@dir", %"Vec"** %ivar2_addr

  ret void
}
%"Isect" = type { i32, double, %"Vec"*, %"Vec"*, %"Vec"*, double, %"Vec"* }
define %"Isect"* @"Isect.new"(double %"@hit", %"Vec"* %"@hit_point", %"Vec"* %"@normal", %"Vec"* %"@color", double %"@distance", %"Vec"* %"@ray_dir") {
  %size = ptrtoint %"Isect"* getelementptr (%"Isect", %"Isect"* null, i32 1) to i64
  %raw_addr = call i8* @GC_malloc(i64 %size)
  %addr = bitcast i8* %raw_addr to %"Isect"*

  call void @llvm.memset.p0i8.i64(i8* %raw_addr, i8 0, i64 %size, i32 4, i1 false)

  %id_addr = getelementptr inbounds %"Isect", %"Isect"* %addr, i32 0, i32 0
  store i32 3, i32* %id_addr
  call void @"Isect#initialize"(%"Isect"* %addr, double %"@hit", %"Vec"* %"@hit_point", %"Vec"* %"@normal", %"Vec"* %"@color", double %"@distance", %"Vec"* %"@ray_dir")
  ret %"Isect"* %addr
}
define double @"Isect#hit"(%"Isect"* %self) {
  %reg174 = getelementptr inbounds %"Isect", %"Isect"* %self, i32 0, i32 1
  %reg175 = load double, double* %reg174
  ret double %reg175
}
define double @"Isect#hit="(%"Isect"* %self, double %value) {
  %reg176 = getelementptr inbounds %"Isect", %"Isect"* %self, i32 0, i32 1
  store double %value, double* %reg176
  ret double %value
}
define %"Vec"* @"Isect#hit_point"(%"Isect"* %self) {
  %reg177 = getelementptr inbounds %"Isect", %"Isect"* %self, i32 0, i32 2
  %reg178 = load %"Vec"*, %"Vec"** %reg177
  ret %"Vec"* %reg178
}
define %"Vec"* @"Isect#hit_point="(%"Isect"* %self, %"Vec"* %value) {
  %reg179 = getelementptr inbounds %"Isect", %"Isect"* %self, i32 0, i32 2
  store %"Vec"* %value, %"Vec"** %reg179
  ret %"Vec"* %value
}
define %"Vec"* @"Isect#normal"(%"Isect"* %self) {
  %reg180 = getelementptr inbounds %"Isect", %"Isect"* %self, i32 0, i32 3
  %reg181 = load %"Vec"*, %"Vec"** %reg180
  ret %"Vec"* %reg181
}
define %"Vec"* @"Isect#normal="(%"Isect"* %self, %"Vec"* %value) {
  %reg182 = getelementptr inbounds %"Isect", %"Isect"* %self, i32 0, i32 3
  store %"Vec"* %value, %"Vec"** %reg182
  ret %"Vec"* %value
}
define %"Vec"* @"Isect#color"(%"Isect"* %self) {
  %reg183 = getelementptr inbounds %"Isect", %"Isect"* %self, i32 0, i32 4
  %reg184 = load %"Vec"*, %"Vec"** %reg183
  ret %"Vec"* %reg184
}
define %"Vec"* @"Isect#color="(%"Isect"* %self, %"Vec"* %value) {
  %reg185 = getelementptr inbounds %"Isect", %"Isect"* %self, i32 0, i32 4
  store %"Vec"* %value, %"Vec"** %reg185
  ret %"Vec"* %value
}
define double @"Isect#distance"(%"Isect"* %self) {
  %reg186 = getelementptr inbounds %"Isect", %"Isect"* %self, i32 0, i32 5
  %reg187 = load double, double* %reg186
  ret double %reg187
}
define double @"Isect#distance="(%"Isect"* %self, double %value) {
  %reg188 = getelementptr inbounds %"Isect", %"Isect"* %self, i32 0, i32 5
  store double %value, double* %reg188
  ret double %value
}
define %"Vec"* @"Isect#ray_dir"(%"Isect"* %self) {
  %reg189 = getelementptr inbounds %"Isect", %"Isect"* %self, i32 0, i32 6
  %reg190 = load %"Vec"*, %"Vec"** %reg189
  ret %"Vec"* %reg190
}
define %"Vec"* @"Isect#ray_dir="(%"Isect"* %self, %"Vec"* %value) {
  %reg191 = getelementptr inbounds %"Isect", %"Isect"* %self, i32 0, i32 6
  store %"Vec"* %value, %"Vec"** %reg191
  ret %"Vec"* %value
}
define void @"Isect#initialize"(%"Isect"* %self, double %"@hit", %"Vec"* %"@hit_point", %"Vec"* %"@normal", %"Vec"* %"@color", double %"@distance", %"Vec"* %"@ray_dir") {
  %ivar1_addr = getelementptr inbounds %"Isect", %"Isect"* %self, i32 0, i32 1
  store double %"@hit", double* %ivar1_addr
  %ivar2_addr = getelementptr inbounds %"Isect", %"Isect"* %self, i32 0, i32 2
  store %"Vec"* %"@hit_point", %"Vec"** %ivar2_addr
  %ivar3_addr = getelementptr inbounds %"Isect", %"Isect"* %self, i32 0, i32 3
  store %"Vec"* %"@normal", %"Vec"** %ivar3_addr
  %ivar4_addr = getelementptr inbounds %"Isect", %"Isect"* %self, i32 0, i32 4
  store %"Vec"* %"@color", %"Vec"** %ivar4_addr
  %ivar5_addr = getelementptr inbounds %"Isect", %"Isect"* %self, i32 0, i32 5
  store double %"@distance", double* %ivar5_addr
  %ivar6_addr = getelementptr inbounds %"Isect", %"Isect"* %self, i32 0, i32 6
  store %"Vec"* %"@ray_dir", %"Vec"** %ivar6_addr

  ret void
}
%"Sphere" = type { i32, double, %"Vec"*, %"Vec"* }
define %"Sphere"* @"Sphere.new"(double %"@radius", %"Vec"* %"@position", %"Vec"* %"@color") {
  %size = ptrtoint %"Sphere"* getelementptr (%"Sphere", %"Sphere"* null, i32 1) to i64
  %raw_addr = call i8* @GC_malloc(i64 %size)
  %addr = bitcast i8* %raw_addr to %"Sphere"*

  call void @llvm.memset.p0i8.i64(i8* %raw_addr, i8 0, i64 %size, i32 4, i1 false)

  %id_addr = getelementptr inbounds %"Sphere", %"Sphere"* %addr, i32 0, i32 0
  store i32 4, i32* %id_addr
  call void @"Sphere#initialize"(%"Sphere"* %addr, double %"@radius", %"Vec"* %"@position", %"Vec"* %"@color")
  ret %"Sphere"* %addr
}
define double @"Sphere#radius"(%"Sphere"* %self) {
  %reg192 = getelementptr inbounds %"Sphere", %"Sphere"* %self, i32 0, i32 1
  %reg193 = load double, double* %reg192
  ret double %reg193
}
define double @"Sphere#radius="(%"Sphere"* %self, double %value) {
  %reg194 = getelementptr inbounds %"Sphere", %"Sphere"* %self, i32 0, i32 1
  store double %value, double* %reg194
  ret double %value
}
define %"Vec"* @"Sphere#position"(%"Sphere"* %self) {
  %reg195 = getelementptr inbounds %"Sphere", %"Sphere"* %self, i32 0, i32 2
  %reg196 = load %"Vec"*, %"Vec"** %reg195
  ret %"Vec"* %reg196
}
define %"Vec"* @"Sphere#position="(%"Sphere"* %self, %"Vec"* %value) {
  %reg197 = getelementptr inbounds %"Sphere", %"Sphere"* %self, i32 0, i32 2
  store %"Vec"* %value, %"Vec"** %reg197
  ret %"Vec"* %value
}
define %"Vec"* @"Sphere#color"(%"Sphere"* %self) {
  %reg198 = getelementptr inbounds %"Sphere", %"Sphere"* %self, i32 0, i32 3
  %reg199 = load %"Vec"*, %"Vec"** %reg198
  ret %"Vec"* %reg199
}
define %"Vec"* @"Sphere#color="(%"Sphere"* %self, %"Vec"* %value) {
  %reg200 = getelementptr inbounds %"Sphere", %"Sphere"* %self, i32 0, i32 3
  store %"Vec"* %value, %"Vec"** %reg200
  ret %"Vec"* %value
}
define void @"Sphere#initialize"(%"Sphere"* %self, double %"@radius", %"Vec"* %"@position", %"Vec"* %"@color") {
  %ivar1_addr = getelementptr inbounds %"Sphere", %"Sphere"* %self, i32 0, i32 1
  store double %"@radius", double* %ivar1_addr
  %ivar2_addr = getelementptr inbounds %"Sphere", %"Sphere"* %self, i32 0, i32 2
  store %"Vec"* %"@position", %"Vec"** %ivar2_addr
  %ivar3_addr = getelementptr inbounds %"Sphere", %"Sphere"* %self, i32 0, i32 3
  store %"Vec"* %"@color", %"Vec"** %ivar3_addr

  ret void
}
define void @"Sphere#intersect!"(%"Sphere"* %self, %"Ray"* %ray, %"Isect"* %isect) {
  %reg201 = call %"Vec"* @"Ray#origin"(%"Ray"* %ray)
  %reg202 = getelementptr inbounds %"Sphere", %"Sphere"* %self, i32 0, i32 2
  %reg203 = load %"Vec"*, %"Vec"** %reg202
  %reg204 = call %"Vec"* @"Vec#vsub"(%"Vec"* %reg201, %"Vec"* %reg203)
  %"rs" = bitcast %"Vec"* %reg204 to %"Vec"*
  %reg205 = call %"Vec"* @"Ray#dir"(%"Ray"* %ray)
  %reg206 = call double @"Vec#vdot"(%"Vec"* %"rs", %"Vec"* %reg205)
  %"b" = bitcast double %reg206 to double
  %reg207 = call double @"Vec#vdot"(%"Vec"* %"rs", %"Vec"* %"rs")
  %reg208 = getelementptr inbounds %"Sphere", %"Sphere"* %self, i32 0, i32 1
  %reg209 = load double, double* %reg208
  %reg210 = getelementptr inbounds %"Sphere", %"Sphere"* %self, i32 0, i32 1
  %reg211 = load double, double* %reg210
  %reg212 = fmul double %reg209, %reg211
  %reg213 = fsub double %reg207, %reg212
  %"c" = bitcast double %reg213 to double
  %reg214 = fmul double %"b", %"b"
  %reg215 = fsub double %reg214, %"c"
  %"d" = bitcast double %reg215 to double
  %reg216 = fcmp ogt double %"d", 0.0
  %reg217 = fsub double 0.0, %"b"
  %reg218 = call double @"sqrt"(double %"d")
  %reg219 = fsub double %reg217, %reg218
  %"t" = bitcast double %reg219 to double
  %reg220 = load double, double* @"EPS"
  %reg221 = fcmp ogt double %"t", %reg220
  %reg222 = and i1 %reg216, %reg221
  %reg223 = call double @"Isect#distance"(%"Isect"* %isect)
  %reg224 = fcmp olt double %"t", %reg223
  %reg225 = and i1 %reg222, %reg224
  br i1 %reg225, label %Then4, label %Else4
Then4:
  %reg226 = call %"Vec"* @"Ray#origin"(%"Ray"* %ray)
  %reg227 = call %"Vec"* @"Ray#dir"(%"Ray"* %ray)
  %reg228 = call %"Vec"* @"Vec#vmul"(%"Vec"* %reg227, double %"t")
  %reg229 = call %"Vec"* @"Vec#vadd"(%"Vec"* %reg226, %"Vec"* %reg228)
  %reg230 = call %"Vec"* @"Isect#hit_point="(%"Isect"* %isect, %"Vec"* %reg229)
  %reg231 = call %"Vec"* @"Isect#hit_point"(%"Isect"* %isect)
  %reg232 = getelementptr inbounds %"Sphere", %"Sphere"* %self, i32 0, i32 2
  %reg233 = load %"Vec"*, %"Vec"** %reg232
  %reg234 = call %"Vec"* @"Vec#vsub"(%"Vec"* %reg231, %"Vec"* %reg233)
  %reg235 = call %"Vec"* @"Vec#vnormalize!"(%"Vec"* %reg234)
  %reg236 = call %"Vec"* @"Isect#normal="(%"Isect"* %isect, %"Vec"* %reg235)
  %reg237 = getelementptr inbounds %"Sphere", %"Sphere"* %self, i32 0, i32 3
  %reg238 = load %"Vec"*, %"Vec"** %reg237
  %reg239 = load %"Vec"*, %"Vec"** @"LIGHT"
  %reg240 = call %"Vec"* @"Isect#normal"(%"Isect"* %isect)
  %reg241 = call double @"Vec#vdot"(%"Vec"* %reg239, %"Vec"* %reg240)
  %reg242 = call double @"clamp"(double %reg241, double 0.1, double 1.0)
  %reg243 = call %"Vec"* @"Vec#vmul"(%"Vec"* %reg238, double %reg242)
  %reg244 = call %"Vec"* @"Isect#color="(%"Isect"* %isect, %"Vec"* %reg243)
  %reg245 = call double @"Isect#distance="(%"Isect"* %isect, double %"t")
  %reg246 = call double @"Isect#hit"(%"Isect"* %isect)
  %reg247 = fadd double %reg246, 1.0
  %reg248 = call double @"Isect#hit="(%"Isect"* %isect, double %reg247)
  %reg249 = call %"Vec"* @"Ray#dir"(%"Ray"* %ray)
  %reg250 = call %"Vec"* @"Isect#ray_dir="(%"Isect"* %isect, %"Vec"* %reg249)
  br label %ThenEnd4
ThenEnd4:
  br label %EndIf4
Else4:
  br label %ElseEnd4
ElseEnd4:
  br label %EndIf4
EndIf4:
  ret void
}
%"Plane" = type { i32, %"Vec"*, %"Vec"*, %"Vec"* }
define %"Plane"* @"Plane.new"(%"Vec"* %"@position", %"Vec"* %"@normal", %"Vec"* %"@color") {
  %size = ptrtoint %"Plane"* getelementptr (%"Plane", %"Plane"* null, i32 1) to i64
  %raw_addr = call i8* @GC_malloc(i64 %size)
  %addr = bitcast i8* %raw_addr to %"Plane"*

  call void @llvm.memset.p0i8.i64(i8* %raw_addr, i8 0, i64 %size, i32 4, i1 false)

  %id_addr = getelementptr inbounds %"Plane", %"Plane"* %addr, i32 0, i32 0
  store i32 5, i32* %id_addr
  call void @"Plane#initialize"(%"Plane"* %addr, %"Vec"* %"@position", %"Vec"* %"@normal", %"Vec"* %"@color")
  ret %"Plane"* %addr
}
define %"Vec"* @"Plane#position"(%"Plane"* %self) {
  %reg252 = getelementptr inbounds %"Plane", %"Plane"* %self, i32 0, i32 1
  %reg253 = load %"Vec"*, %"Vec"** %reg252
  ret %"Vec"* %reg253
}
define %"Vec"* @"Plane#position="(%"Plane"* %self, %"Vec"* %value) {
  %reg254 = getelementptr inbounds %"Plane", %"Plane"* %self, i32 0, i32 1
  store %"Vec"* %value, %"Vec"** %reg254
  ret %"Vec"* %value
}
define %"Vec"* @"Plane#normal"(%"Plane"* %self) {
  %reg255 = getelementptr inbounds %"Plane", %"Plane"* %self, i32 0, i32 2
  %reg256 = load %"Vec"*, %"Vec"** %reg255
  ret %"Vec"* %reg256
}
define %"Vec"* @"Plane#normal="(%"Plane"* %self, %"Vec"* %value) {
  %reg257 = getelementptr inbounds %"Plane", %"Plane"* %self, i32 0, i32 2
  store %"Vec"* %value, %"Vec"** %reg257
  ret %"Vec"* %value
}
define %"Vec"* @"Plane#color"(%"Plane"* %self) {
  %reg258 = getelementptr inbounds %"Plane", %"Plane"* %self, i32 0, i32 3
  %reg259 = load %"Vec"*, %"Vec"** %reg258
  ret %"Vec"* %reg259
}
define %"Vec"* @"Plane#color="(%"Plane"* %self, %"Vec"* %value) {
  %reg260 = getelementptr inbounds %"Plane", %"Plane"* %self, i32 0, i32 3
  store %"Vec"* %value, %"Vec"** %reg260
  ret %"Vec"* %value
}
define void @"Plane#initialize"(%"Plane"* %self, %"Vec"* %"@position", %"Vec"* %"@normal", %"Vec"* %"@color") {
  %ivar1_addr = getelementptr inbounds %"Plane", %"Plane"* %self, i32 0, i32 1
  store %"Vec"* %"@position", %"Vec"** %ivar1_addr
  %ivar2_addr = getelementptr inbounds %"Plane", %"Plane"* %self, i32 0, i32 2
  store %"Vec"* %"@normal", %"Vec"** %ivar2_addr
  %ivar3_addr = getelementptr inbounds %"Plane", %"Plane"* %self, i32 0, i32 3
  store %"Vec"* %"@color", %"Vec"** %ivar3_addr

  ret void
}
define void @"Plane#intersect!"(%"Plane"* %self, %"Ray"* %ray, %"Isect"* %isect) {
  %reg261 = getelementptr inbounds %"Plane", %"Plane"* %self, i32 0, i32 1
  %reg262 = load %"Vec"*, %"Vec"** %reg261
  %reg263 = getelementptr inbounds %"Plane", %"Plane"* %self, i32 0, i32 2
  %reg264 = load %"Vec"*, %"Vec"** %reg263
  %reg265 = call double @"Vec#vdot"(%"Vec"* %reg262, %"Vec"* %reg264)
  %reg266 = fsub double 0.0, %reg265
  %"d" = bitcast double %reg266 to double
  %reg267 = call %"Vec"* @"Ray#dir"(%"Ray"* %ray)
  %reg268 = getelementptr inbounds %"Plane", %"Plane"* %self, i32 0, i32 2
  %reg269 = load %"Vec"*, %"Vec"** %reg268
  %reg270 = call double @"Vec#vdot"(%"Vec"* %reg267, %"Vec"* %reg269)
  %"v" = bitcast double %reg270 to double
  %reg271 = call %"Vec"* @"Ray#origin"(%"Ray"* %ray)
  %reg272 = getelementptr inbounds %"Plane", %"Plane"* %self, i32 0, i32 2
  %reg273 = load %"Vec"*, %"Vec"** %reg272
  %reg274 = call double @"Vec#vdot"(%"Vec"* %reg271, %"Vec"* %reg273)
  %reg275 = fadd double %reg274, %"d"
  %reg276 = fsub double 0.0, %reg275
  %reg277 = fdiv double %reg276, %"v"
  %"t" = bitcast double %reg277 to double
  %reg278 = load double, double* @"EPS"
  %reg279 = fcmp ogt double %"t", %reg278
  %reg280 = call double @"Isect#distance"(%"Isect"* %isect)
  %reg281 = fcmp olt double %"t", %reg280
  %reg282 = and i1 %reg279, %reg281
  br i1 %reg282, label %Then5, label %Else5
Then5:
  %reg283 = call %"Vec"* @"Ray#origin"(%"Ray"* %ray)
  %reg284 = call %"Vec"* @"Ray#dir"(%"Ray"* %ray)
  %reg285 = call %"Vec"* @"Vec#vmul"(%"Vec"* %reg284, double %"t")
  %reg286 = call %"Vec"* @"Vec#vadd"(%"Vec"* %reg283, %"Vec"* %reg285)
  %reg287 = call %"Vec"* @"Isect#hit_point="(%"Isect"* %isect, %"Vec"* %reg286)
  %reg288 = getelementptr inbounds %"Plane", %"Plane"* %self, i32 0, i32 2
  %reg289 = load %"Vec"*, %"Vec"** %reg288
  %reg290 = call %"Vec"* @"Isect#normal="(%"Isect"* %isect, %"Vec"* %reg289)
  %reg291 = load %"Vec"*, %"Vec"** @"LIGHT"
  %reg292 = call %"Vec"* @"Isect#normal"(%"Isect"* %isect)
  %reg293 = call double @"Vec#vdot"(%"Vec"* %reg291, %"Vec"* %reg292)
  %reg294 = call double @"clamp"(double %reg293, double 0.1, double 1.0)
  %"d2" = bitcast double %reg294 to double
  %reg295 = call %"Vec"* @"Isect#hit_point"(%"Isect"* %isect)
  %reg296 = call double @"Vec#x"(%"Vec"* %reg295)
  br label %mod6a
mod6a:
  %reg298 = frem double %reg296, 2.0
  %reg300 = fmul double %reg296, 2.0
  %reg301 = fcmp olt double %reg300, 0.0
  %reg302 = fcmp one double %reg298, 0.0
  %reg303 = and i1 %reg301, %reg302
  br i1 %reg303, label %mod6b, label %mod6
mod6b:
  %reg299 = fadd double %reg298, 2.0
  br label %mod6
mod6:
  %reg297 = phi double [%reg298, %mod6a], [%reg299, %mod6b]
  %"m" = bitcast double %reg297 to double
  %reg304 = call %"Vec"* @"Isect#hit_point"(%"Isect"* %isect)
  %reg305 = call double @"Vec#z"(%"Vec"* %reg304)
  br label %mod7a
mod7a:
  %reg307 = frem double %reg305, 2.0
  %reg309 = fmul double %reg305, 2.0
  %reg310 = fcmp olt double %reg309, 0.0
  %reg311 = fcmp one double %reg307, 0.0
  %reg312 = and i1 %reg310, %reg311
  br i1 %reg312, label %mod7b, label %mod7
mod7b:
  %reg308 = fadd double %reg307, 2.0
  br label %mod7
mod7:
  %reg306 = phi double [%reg307, %mod7a], [%reg308, %mod7b]
  %"n" = bitcast double %reg306 to double
  %reg313 = fcmp ogt double %"m", 1.0
  %reg314 = fcmp ogt double %"n", 1.0
  %reg315 = and i1 %reg313, %reg314
  %reg316 = fcmp olt double %"m", 1.0
  %reg317 = fcmp olt double %"n", 1.0
  %reg318 = and i1 %reg316, %reg317
  %reg319 = or i1 %reg315, %reg318
  br i1 %reg319, label %Then8, label %Else8
Then8:
  %reg320 = fmul double %"d2", 0.5
  br label %ThenEnd8
ThenEnd8:
  br label %EndIf8
Else8:
  br label %ElseEnd8
ElseEnd8:
  br label %EndIf8
EndIf8:
  %reg321 = phi double [%reg320, %ThenEnd8], [%"d2", %ElseEnd8]
  %"d3" = bitcast double %reg321 to double
  %reg322 = call %"Vec"* @"Isect#hit_point"(%"Isect"* %isect)
  %reg323 = call double @"Vec#z"(%"Vec"* %reg322)
  %reg324 = call double @"fabs"(double %reg323)
  %"abs" = bitcast double %reg324 to double
  %reg325 = fcmp olt double %"abs", 25.0
  br i1 %reg325, label %Then9, label %Else9
Then9:
  br label %ThenEnd9
ThenEnd9:
  br label %EndIf9
Else9:
  br label %ElseEnd9
ElseEnd9:
  br label %EndIf9
EndIf9:
  %reg326 = phi double [%"abs", %ThenEnd9], [25.0, %ElseEnd9]
  %reg327 = fmul double %reg326, 0.04
  %reg328 = fsub double 1.0, %reg327
  %"f" = bitcast double %reg328 to double
  %reg329 = getelementptr inbounds %"Plane", %"Plane"* %self, i32 0, i32 3
  %reg330 = load %"Vec"*, %"Vec"** %reg329
  %reg331 = fmul double %"d3", %"f"
  %reg332 = call %"Vec"* @"Vec#vmul"(%"Vec"* %reg330, double %reg331)
  %reg333 = call %"Vec"* @"Isect#color="(%"Isect"* %isect, %"Vec"* %reg332)
  %reg334 = call double @"Isect#distance="(%"Isect"* %isect, double %"t")
  %reg335 = call double @"Isect#hit"(%"Isect"* %isect)
  %reg336 = fadd double %reg335, 1.0
  %reg337 = call double @"Isect#hit="(%"Isect"* %isect, double %reg336)
  %reg338 = call %"Vec"* @"Ray#dir"(%"Ray"* %ray)
  %reg339 = call %"Vec"* @"Isect#ray_dir="(%"Isect"* %isect, %"Vec"* %reg338)
  br label %ThenEnd5
ThenEnd5:
  br label %EndIf5
Else5:
  br label %ElseEnd5
ElseEnd5:
  br label %EndIf5
EndIf5:
  ret void
}
define double @"color"(double %t) {
  %reg341 = load double, double* @"IMAGE_DEPTH"
  %reg342 = call double @"clamp"(double %t, double 0.0, double 1.0)
  %reg343 = fmul double %reg341, %reg342
  %"ret" = bitcast double %reg343 to double
  %reg344 = load double, double* @"IMAGE_DEPTH"
  %reg345 = fcmp oeq double %"ret", %reg344
  br i1 %reg345, label %Then10, label %Else10
Then10:
  %reg346 = load double, double* @"IMAGE_DEPTH"
  %reg347 = fsub double %reg346, 1.0
  br label %ThenEnd10
ThenEnd10:
  br label %EndIf10
Else10:
  br label %ElseEnd10
ElseEnd10:
  br label %EndIf10
EndIf10:
  %reg348 = phi double [%reg347, %ThenEnd10], [%"ret", %ElseEnd10]
  ret double %reg348
}
define void @"print_col"(%"Vec"* %c) {
  %reg349 = call double @"Vec#x"(%"Vec"* %c)
  %reg350 = call double @"color"(double %reg349)
  %reg351 = fptosi double %reg350 to i32
  call void @"putd"(i32 %reg351)
  %reg353 = fptosi double 32.0 to i32
  %reg354 = call i32 @"putchar"(i32 %reg353)
  %reg355 = sitofp i32 %reg354 to double
  %reg356 = call double @"Vec#y"(%"Vec"* %c)
  %reg357 = call double @"color"(double %reg356)
  %reg358 = fptosi double %reg357 to i32
  call void @"putd"(i32 %reg358)
  %reg360 = fptosi double 32.0 to i32
  %reg361 = call i32 @"putchar"(i32 %reg360)
  %reg362 = sitofp i32 %reg361 to double
  %reg363 = call double @"Vec#z"(%"Vec"* %c)
  %reg364 = call double @"color"(double %reg363)
  %reg365 = fptosi double %reg364 to i32
  call void @"putd"(i32 %reg365)
  %reg367 = fptosi double 10.0 to i32
  %reg368 = call i32 @"putchar"(i32 %reg367)
  %reg369 = sitofp i32 %reg368 to double
  ret void
}
define void @"intersect!"(%"Ray"* %ray, %"Isect"* %i) {
  %reg370 = load %"Sphere"*, %"Sphere"** @"SPHERE1"
  call void @"Sphere#intersect!"(%"Sphere"* %reg370, %"Ray"* %ray, %"Isect"* %i)
  %reg372 = load %"Sphere"*, %"Sphere"** @"SPHERE2"
  call void @"Sphere#intersect!"(%"Sphere"* %reg372, %"Ray"* %ray, %"Isect"* %i)
  %reg374 = load %"Sphere"*, %"Sphere"** @"SPHERE3"
  call void @"Sphere#intersect!"(%"Sphere"* %reg374, %"Ray"* %ray, %"Isect"* %i)
  %reg376 = load %"Plane"*, %"Plane"** @"PLANE"
  call void @"Plane#intersect!"(%"Plane"* %reg376, %"Ray"* %ray, %"Isect"* %i)
  ret void
}
define i32 @main() {
  call void @GC_init()
  store double 700.0, double* @"IMAGE_WIDTH"
  store double 700.0, double* @"IMAGE_HEIGHT"
  store double 256.0, double* @"IMAGE_DEPTH"
  store double 0.0001, double* @"EPS"
  store double 4.0, double* @"MAX_REF"
  %reg1 = call %"Vec"* @"Vec.new"(double 0.577, double 0.577, double 0.577)
  store %"Vec"* %reg1, %"Vec"** @"LIGHT"
  %reg2 = fsub double 0.0, 1.0
  %reg3 = call %"Vec"* @"Vec.new"(double 0.0, double %reg2, double 0.0)
  %reg4 = call %"Vec"* @"Vec.new"(double 0.0, double 1.0, double 0.0)
  %reg5 = call %"Vec"* @"Vec.new"(double 1.0, double 1.0, double 1.0)
  %reg6 = call %"Plane"* @"Plane.new"(%"Vec"* %reg3, %"Vec"* %reg4, %"Vec"* %reg5)
  store %"Plane"* %reg6, %"Plane"** @"PLANE"
  store double 0.0, double* @"T"
  %reg7 = fsub double 0.0, 0.5
  %reg8 = call double @"sin"(double 0.0)
  %reg9 = call %"Vec"* @"Vec.new"(double 0.0, double %reg7, double %reg8)
  %reg10 = call %"Vec"* @"Vec.new"(double 1.0, double 0.0, double 0.0)
  %reg11 = call %"Sphere"* @"Sphere.new"(double 0.5, %"Vec"* %reg9, %"Vec"* %reg10)
  store %"Sphere"* %reg11, %"Sphere"** @"SPHERE1"
  %reg12 = load double, double* @"T"
  %reg13 = fmul double %reg12, 0.666
  %reg14 = call double @"cos"(double %reg13)
  %reg15 = call %"Vec"* @"Vec.new"(double 2.0, double 0.0, double %reg14)
  %reg16 = call %"Vec"* @"Vec.new"(double 0.0, double 1.0, double 0.0)
  %reg17 = call %"Sphere"* @"Sphere.new"(double 1.0, %"Vec"* %reg15, %"Vec"* %reg16)
  store %"Sphere"* %reg17, %"Sphere"** @"SPHERE2"
  %reg18 = fsub double 0.0, 2.0
  %reg19 = load double, double* @"T"
  %reg20 = fmul double %reg19, 0.333
  %reg21 = call double @"cos"(double %reg20)
  %reg22 = call %"Vec"* @"Vec.new"(double %reg18, double 0.5, double %reg21)
  %reg23 = call %"Vec"* @"Vec.new"(double 0.0, double 0.0, double 1.0)
  %reg24 = call %"Sphere"* @"Sphere.new"(double 1.5, %"Vec"* %reg22, %"Vec"* %reg23)
  store %"Sphere"* %reg24, %"Sphere"** @"SPHERE3"
  %reg378 = fptosi double 80.0 to i32
  %reg379 = call i32 @"putchar"(i32 %reg378)
  %reg380 = sitofp i32 %reg379 to double
  %reg381 = fptosi double 3.0 to i32
  call void @"putd"(i32 %reg381)
  %reg383 = fptosi double 10.0 to i32
  %reg384 = call i32 @"putchar"(i32 %reg383)
  %reg385 = sitofp i32 %reg384 to double
  %reg386 = load double, double* @"IMAGE_WIDTH"
  %reg387 = fptosi double %reg386 to i32
  call void @"putd"(i32 %reg387)
  %reg389 = fptosi double 32.0 to i32
  %reg390 = call i32 @"putchar"(i32 %reg389)
  %reg391 = sitofp i32 %reg390 to double
  %reg392 = load double, double* @"IMAGE_HEIGHT"
  %reg393 = fptosi double %reg392 to i32
  call void @"putd"(i32 %reg393)
  %reg395 = fptosi double 10.0 to i32
  %reg396 = call i32 @"putchar"(i32 %reg395)
  %reg397 = sitofp i32 %reg396 to double
  %reg398 = fptosi double 255.0 to i32
  call void @"putd"(i32 %reg398)
  %reg400 = fptosi double 10.0 to i32
  %reg401 = call i32 @"putchar"(i32 %reg400)
  %reg402 = sitofp i32 %reg401 to double
  br label %For3
For3:
  %reg403 = load double, double* @"IMAGE_HEIGHT"
  br label %Loop3
Loop3:
  %row = phi double [0.0, %For3], [%fori3, %ForInc3]
  %forc3 = fcmp oge double %row, %reg403
  br i1 %forc3, label %EndFor3, label %ForBody3
ForBody3:
  br label %For2
For2:
  %reg404 = load double, double* @"IMAGE_WIDTH"
  br label %Loop2
Loop2:
  %col = phi double [0.0, %For2], [%fori2, %ForInc2]
  %forc2 = fcmp oge double %col, %reg404
  br i1 %forc2, label %EndFor2, label %ForBody2
ForBody2:
  %reg405 = load double, double* @"IMAGE_WIDTH"
  %reg406 = fdiv double %reg405, 2.0
  %reg407 = fdiv double %col, %reg406
  %reg408 = fsub double %reg407, 1.0
  %"x" = bitcast double %reg408 to double
  %reg409 = load double, double* @"IMAGE_HEIGHT"
  %reg410 = fsub double %reg409, %row
  %reg411 = load double, double* @"IMAGE_HEIGHT"
  %reg412 = fdiv double %reg411, 2.0
  %reg413 = fdiv double %reg410, %reg412
  %reg414 = fsub double %reg413, 1.0
  %"y" = bitcast double %reg414 to double
  %reg415 = call %"Vec"* @"Vec.new"(double 0.0, double 2.0, double 6.0)
  %reg416 = fsub double 0.0, 1.0
  %reg417 = call %"Vec"* @"Vec.new"(double %"x", double %"y", double %reg416)
  %reg418 = call %"Vec"* @"Vec#vnormalize!"(%"Vec"* %reg417)
  %reg419 = call %"Ray"* @"Ray.new"(%"Vec"* %reg415, %"Vec"* %reg418)
  %"ray" = bitcast %"Ray"* %reg419 to %"Ray"*
  %reg420 = call %"Vec"* @"Vec.new"(double 0.0, double 0.0, double 0.0)
  %reg421 = call %"Vec"* @"Vec.new"(double 0.0, double 0.0, double 0.0)
  %reg422 = call %"Vec"* @"Vec.new"(double 0.0, double 0.0, double 0.0)
  %reg423 = call %"Vec"* @"Vec.new"(double 0.0, double 0.0, double 0.0)
  %reg424 = call %"Isect"* @"Isect.new"(double 0.0, %"Vec"* %reg420, %"Vec"* %reg421, %"Vec"* %reg422, double 1000000000000000000000000000000.0, %"Vec"* %reg423)
  %"i" = bitcast %"Isect"* %reg424 to %"Isect"*
  call void @"intersect!"(%"Ray"* %"ray", %"Isect"* %"i")
  %reg426 = call double @"Isect#hit"(%"Isect"* %"i")
  %reg427 = fcmp ogt double %reg426, 0.0
  br i1 %reg427, label %Then11, label %Else11
Then11:
  %reg428 = call %"Vec"* @"Isect#color"(%"Isect"* %"i")
  %"dest_col" = alloca %"Vec"*
  store %"Vec"* %reg428, %"Vec"** %"dest_col"
  %reg429 = call %"Vec"* @"Vec.new"(double 1.0, double 1.0, double 1.0)
  %reg430 = call %"Vec"* @"Isect#color"(%"Isect"* %"i")
  %reg431 = call %"Vec"* @"Vec#vmulti"(%"Vec"* %reg429, %"Vec"* %reg430)
  %"temp_col" = alloca %"Vec"*
  store %"Vec"* %reg431, %"Vec"** %"temp_col"
  br label %For1
For1:
  %reg432 = load double, double* @"MAX_REF"
  br label %Loop1
Loop1:
  %j = phi double [1.0, %For1], [%fori1, %ForInc1]
  %forc1 = fcmp oge double %j, %reg432
  br i1 %forc1, label %EndFor1, label %ForBody1
ForBody1:
  %reg433 = call %"Vec"* @"Isect#hit_point"(%"Isect"* %"i")
  %reg434 = call %"Vec"* @"Isect#normal"(%"Isect"* %"i")
  %reg435 = load double, double* @"EPS"
  %reg436 = call %"Vec"* @"Vec#vmul"(%"Vec"* %reg434, double %reg435)
  %reg437 = call %"Vec"* @"Vec#vadd"(%"Vec"* %reg433, %"Vec"* %reg436)
  %reg438 = call %"Vec"* @"Isect#ray_dir"(%"Isect"* %"i")
  %reg439 = call %"Vec"* @"Isect#normal"(%"Isect"* %"i")
  %reg440 = call %"Vec"* @"Vec#reflect"(%"Vec"* %reg438, %"Vec"* %reg439)
  %reg441 = call %"Ray"* @"Ray.new"(%"Vec"* %reg437, %"Vec"* %reg440)
  %"q" = bitcast %"Ray"* %reg441 to %"Ray"*
  call void @"intersect!"(%"Ray"* %"q", %"Isect"* %"i")
  %reg443 = call double @"Isect#hit"(%"Isect"* %"i")
  %reg444 = fcmp ogt double %reg443, %j
  br i1 %reg444, label %Then12, label %Else12
Then12:
  %reg445 = load %"Vec"*, %"Vec"** %"dest_col"
  %reg446 = load %"Vec"*, %"Vec"** %"temp_col"
  %reg447 = call %"Vec"* @"Isect#color"(%"Isect"* %"i")
  %reg448 = call %"Vec"* @"Vec#vmulti"(%"Vec"* %reg446, %"Vec"* %reg447)
  %reg449 = call %"Vec"* @"Vec#vadd"(%"Vec"* %reg445, %"Vec"* %reg448)
  store %"Vec"* %reg449, %"Vec"** %"dest_col"
  %reg450 = load %"Vec"*, %"Vec"** %"temp_col"
  %reg451 = call %"Vec"* @"Isect#color"(%"Isect"* %"i")
  %reg452 = call %"Vec"* @"Vec#vmulti"(%"Vec"* %reg450, %"Vec"* %reg451)
  store %"Vec"* %reg452, %"Vec"** %"temp_col"
  br label %ThenEnd12
ThenEnd12:
  br label %EndIf12
Else12:
  br label %ElseEnd12
ElseEnd12:
  br label %EndIf12
EndIf12:
  br label %ForInc1
ForInc1:
  %fori1 = fadd double %j, 1.0
  br label %Loop1
EndFor1:
  %reg454 = load %"Vec"*, %"Vec"** %"dest_col"
  call void @"print_col"(%"Vec"* %reg454)
  br label %ThenEnd11
ThenEnd11:
  br label %EndIf11
Else11:
  %reg456 = call %"Vec"* @"Ray#dir"(%"Ray"* %"ray")
  %reg457 = call double @"Vec#y"(%"Vec"* %reg456)
  %reg458 = call %"Vec"* @"Ray#dir"(%"Ray"* %"ray")
  %reg459 = call double @"Vec#y"(%"Vec"* %reg458)
  %reg460 = call %"Vec"* @"Ray#dir"(%"Ray"* %"ray")
  %reg461 = call double @"Vec#y"(%"Vec"* %reg460)
  %reg462 = call %"Vec"* @"Vec.new"(double %reg457, double %reg459, double %reg461)
  call void @"print_col"(%"Vec"* %reg462)
  br label %ElseEnd11
ElseEnd11:
  br label %EndIf11
EndIf11:
  br label %ForInc2
ForInc2:
  %fori2 = fadd double %col, 1.0
  br label %Loop2
EndFor2:
  br label %ForInc3
ForInc3:
  %fori3 = fadd double %row, 1.0
  br label %Loop3
EndFor3:
  ret i32 0
}
