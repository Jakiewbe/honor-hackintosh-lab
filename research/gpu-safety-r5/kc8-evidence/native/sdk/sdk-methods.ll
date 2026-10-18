; ModuleID = '/Users/runner/work/_temp/g1-kc8/sdk/sdk-methods.cpp'
source_filename = "/Users/runner/work/_temp/g1-kc8/sdk/sdk-methods.cpp"
target datalayout = "e-m:o-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx15.5.0"

@_ZN11IOPCIDevice9metaClassE = external constant ptr, align 8
@_ZN20IOACPIPlatformDevice9metaClassE = external constant ptr, align 8

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define zeroext i8 @kc_read8(ptr noundef %0, i64 noundef %1) local_unnamed_addr #0 {
  %3 = tail call zeroext i8 @_ZN11IOPCIDevice19extendedConfigRead8Ey(ptr noundef %0, i64 noundef %1) #3
  ret i8 %3
}

; Function Attrs: noimplicitfloat noredzone
declare zeroext i8 @_ZN11IOPCIDevice19extendedConfigRead8Ey(ptr noundef, i64 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @kc_write8(ptr noundef %0, i64 noundef %1, i8 noundef zeroext %2) local_unnamed_addr #0 {
  tail call void @_ZN11IOPCIDevice20extendedConfigWrite8Eyh(ptr noundef %0, i64 noundef %1, i8 noundef zeroext %2) #3
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN11IOPCIDevice20extendedConfigWrite8Eyh(ptr noundef, i64 noundef, i8 noundef zeroext) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define zeroext i16 @kc_read16(ptr noundef %0, i64 noundef %1) local_unnamed_addr #0 {
  %3 = tail call zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef %0, i64 noundef %1) #3
  ret i16 %3
}

; Function Attrs: noimplicitfloat noredzone
declare zeroext i16 @_ZN11IOPCIDevice20extendedConfigRead16Ey(ptr noundef, i64 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @kc_write16(ptr noundef %0, i64 noundef %1, i16 noundef zeroext %2) local_unnamed_addr #0 {
  tail call void @_ZN11IOPCIDevice21extendedConfigWrite16Eyt(ptr noundef %0, i64 noundef %1, i16 noundef zeroext %2) #3
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN11IOPCIDevice21extendedConfigWrite16Eyt(ptr noundef, i64 noundef, i16 noundef zeroext) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define i32 @kc_read32(ptr noundef %0, i64 noundef %1) local_unnamed_addr #0 {
  %3 = tail call i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef %0, i64 noundef %1) #3
  ret i32 %3
}

; Function Attrs: noimplicitfloat noredzone
declare i32 @_ZN11IOPCIDevice20extendedConfigRead32Ey(ptr noundef, i64 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress noimplicitfloat noredzone nounwind ssp
define void @kc_write32(ptr noundef %0, i64 noundef %1, i32 noundef %2) local_unnamed_addr #0 {
  tail call void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef %0, i64 noundef %1, i32 noundef %2) #3
  ret void
}

; Function Attrs: noimplicitfloat noredzone
declare void @_ZN11IOPCIDevice21extendedConfigWrite32Eyj(ptr noundef, i64 noundef, i32 noundef) local_unnamed_addr #1

; Function Attrs: mustprogress nofree noimplicitfloat norecurse noredzone nosync nounwind ssp willreturn memory(none)
define noundef nonnull ptr @kc_pci_meta() local_unnamed_addr #2 {
  ret ptr @_ZN11IOPCIDevice9metaClassE
}

; Function Attrs: mustprogress nofree noimplicitfloat norecurse noredzone nosync nounwind ssp willreturn memory(none)
define noundef nonnull ptr @kc_acpi_meta() local_unnamed_addr #2 {
  ret ptr @_ZN20IOACPIPlatformDevice9metaClassE
}

attributes #0 = { mustprogress noimplicitfloat noredzone nounwind ssp "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #1 = { noimplicitfloat noredzone "frame-pointer"="all" "no-builtins" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #2 = { mustprogress nofree noimplicitfloat norecurse noredzone nosync nounwind ssp willreturn memory(none) "frame-pointer"="all" "min-legal-vector-width"="0" "no-builtins" "no-trapping-math"="true" "probe-stack"="__chkstk_darwin" "stack-protector-buffer-size"="8" "target-cpu"="penryn" "target-features"="+cmov,+cx16,+cx8,+fxsr,+mmx,+sahf,+sse,+sse2,+sse3,+sse4.1,+ssse3,+x87" "tune-cpu"="generic" }
attributes #3 = { nobuiltin noimplicitfloat noredzone nounwind "no-builtins" }

!llvm.module.flags = !{!0, !1, !2}
!llvm.ident = !{!3}

!0 = !{i32 2, !"SDK Version", [2 x i32] [i32 15, i32 5]}
!1 = !{i32 1, !"wchar_size", i32 4}
!2 = !{i32 7, !"frame-pointer", i32 2}
!3 = !{!"Apple clang version 17.0.0 (clang-1700.0.13.5)"}
