/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20250404 (64-bit version)
 * Copyright (c) 2000 - 2025 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of <WORKDIR>/input/reg_SSD7_HONOR_WmiTable_00001000.bin
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x00000E74 (3700)
 *     Revision         0x01
 *     Checksum         0x09
 *     OEM ID           "HONOR"
 *     OEM Table ID     "WmiTable"
 *     OEM Revision     0x00001000 (4096)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20200717 (538969879)
 */
DefinitionBlock ("", "SSDT", 1, "HONOR", "WmiTable", 0x00001000)
{
    External (_SB_.PC00.LPCB.EC0_.AOPT, UnknownObj)
    External (_SB_.PC00.LPCB.EC0_.WMEN, UnknownObj)
    External (GADI, MethodObj)    // 1 Arguments
    External (GAIT, MethodObj)    // 1 Arguments
    External (GAOP, MethodObj)    // 1 Arguments
    External (GBAD, MethodObj)    // 1 Arguments
    External (GBAI, MethodObj)    // 1 Arguments
    External (GBCM, MethodObj)    // 1 Arguments
    External (GBTM, MethodObj)    // 1 Arguments
    External (GBTT, MethodObj)    // 1 Arguments
    External (GCII, MethodObj)    // 1 Arguments
    External (GCPL, MethodObj)    // 1 Arguments
    External (GCVA, MethodObj)    // 1 Arguments
    External (GDXD, MethodObj)    // 1 Arguments
    External (GECL, MethodObj)    // 1 Arguments
    External (GECV, MethodObj)    // 1 Arguments
    External (GFCC, MethodObj)    // 1 Arguments
    External (GFNM, MethodObj)    // 1 Arguments
    External (GFNS, MethodObj)    // 1 Arguments
    External (GFRS, MethodObj)    // 1 Arguments
    External (GKBM, MethodObj)    // 1 Arguments
    External (GKBT, MethodObj)    // 1 Arguments
    External (GLED, MethodObj)    // 1 Arguments
    External (GLGO, MethodObj)    // 1 Arguments
    External (GLIV, MethodObj)    // 1 Arguments
    External (GLOG, MethodObj)    // 1 Arguments
    External (GNTB, MethodObj)    // 1 Arguments
    External (GODP, MethodObj)    // 1 Arguments
    External (GOSF, MethodObj)    // 1 Arguments
    External (GPCI, MethodObj)    // 1 Arguments
    External (GPDV, MethodObj)    // 1 Arguments
    External (GPFM, MethodObj)    // 1 Arguments
    External (GPSI, MethodObj)    // 1 Arguments
    External (GSTP, MethodObj)    // 1 Arguments
    External (GSWL, MethodObj)    // 1 Arguments
    External (GTMP, MethodObj)    // 1 Arguments
    External (GTPS, MethodObj)    // 1 Arguments
    External (GTSI, MethodObj)    // 1 Arguments
    External (GTUB, MethodObj)    // 1 Arguments
    External (GVER, MethodObj)    // 1 Arguments
    External (GWKM, MethodObj)    // 1 Arguments
    External (HADS, MethodObj)    // 1 Arguments
    External (ISIA, MethodObj)    // 1 Arguments
    External (SAOP, MethodObj)    // 1 Arguments
    External (SBAD, MethodObj)    // 1 Arguments
    External (SBCM, MethodObj)    // 1 Arguments
    External (SBTT, MethodObj)    // 1 Arguments
    External (SECL, MethodObj)    // 1 Arguments
    External (SECV, MethodObj)    // 1 Arguments
    External (SFNM, MethodObj)    // 1 Arguments
    External (SFNS, MethodObj)    // 1 Arguments
    External (SFRS, MethodObj)    // 1 Arguments
    External (SKBL, MethodObj)    // 1 Arguments
    External (SKBM, MethodObj)    // 1 Arguments
    External (SKBT, MethodObj)    // 1 Arguments
    External (SLED, MethodObj)    // 1 Arguments
    External (SLGO, MethodObj)    // 1 Arguments
    External (SLIV, MethodObj)    // 1 Arguments
    External (SLOG, MethodObj)    // 1 Arguments
    External (SMLS, MethodObj)    // 1 Arguments
    External (SNTB, MethodObj)    // 1 Arguments
    External (SODP, MethodObj)    // 1 Arguments
    External (SOSF, MethodObj)    // 1 Arguments
    External (SPDV, MethodObj)    // 1 Arguments
    External (SPFM, MethodObj)    // 1 Arguments
    External (SPLV, MethodObj)    // 1 Arguments
    External (SSTP, MethodObj)    // 1 Arguments
    External (SSWL, MethodObj)    // 1 Arguments
    External (STMP, MethodObj)    // 1 Arguments
    External (STMT, MethodObj)    // 1 Arguments
    External (STPS, MethodObj)    // 1 Arguments
    External (STUB, MethodObj)    // 1 Arguments
    External (SWKM, MethodObj)    // 1 Arguments

    OperationRegion (HNVS, SystemMemory, 0x44967000, 0x00000168)
    Field (HNVS, AnyAcc, NoLock, Preserve)
    {
        DAIN,   512, 
        DAOU,   2048, 
        ORV1,   64, 
        UPEN,   8, 
        HDEN,   8, 
        CAEN,   8, 
        AUEN,   8, 
        WFEN,   8, 
        BTHE,   8, 
        KSVA,   8, 
        OWUS,   8, 
        SEBO,   8, 
        TPCM,   8, 
        BVAR,   8, 
        MFGM,   8, 
        FPTE,   8, 
        FPSU,   8, 
        ILVT,   8, 
        WKOL,   8, 
        PDEN,   8, 
        OSAR,   8, 
        HONS,   8, 
        ORV2,   104
    }

    Scope (\_SB)
    {
        Mutex (MUTW, 0x00)
        Device (WMI1)
        {
            Name (_HID, EisaId ("PNP0C14") /* Windows Management Instrumentation Device */)  // _HID: Hardware ID
            Name (_UID, "HWMI")  // _UID: Unique ID
            Name (WMIC, Zero)
            Name (_WDG, Buffer (0x3C)
            {
                /* 0000 */  0x5B, 0x0F, 0xBC, 0xAB, 0xA1, 0x8E, 0xD1, 0x11,  // [.......
                /* 0008 */  0xA0, 0x00, 0xC9, 0x06, 0x29, 0x10, 0x00, 0x00,  // ....)...
                /* 0010 */  0x41, 0x41, 0x01, 0x02, 0x5C, 0x0F, 0xBC, 0xAB,  // AA..\...
                /* 0018 */  0xA1, 0x8E, 0xD1, 0x11, 0xA0, 0x00, 0xC9, 0x06,  // ........
                /* 0020 */  0x29, 0x10, 0x00, 0x00, 0xA0, 0x00, 0x01, 0x08,  // ).......
                /* 0028 */  0x21, 0x12, 0x90, 0x05, 0x66, 0xD5, 0xD1, 0x11,  // !...f...
                /* 0030 */  0xB2, 0xF0, 0x00, 0xA0, 0xC9, 0x06, 0x29, 0x10,  // ......).
                /* 0038 */  0x42, 0x41, 0x01, 0x00                           // BA..
            })
            Name (WQBA, Buffer (0x03EE)
            {
                /* 0000 */  0x46, 0x4F, 0x4D, 0x42, 0x01, 0x00, 0x00, 0x00,  // FOMB....
                /* 0008 */  0xDE, 0x03, 0x00, 0x00, 0x38, 0x0C, 0x00, 0x00,  // ....8...
                /* 0010 */  0x44, 0x53, 0x00, 0x01, 0x1A, 0x7D, 0xDA, 0x54,  // DS...}.T
                /* 0018 */  0x18, 0xD3, 0x85, 0x00, 0x01, 0x06, 0x18, 0x42,  // .......B
                /* 0020 */  0x10, 0x05, 0x10, 0x92, 0xE5, 0x81, 0x42, 0x04,  // ......B.
                /* 0028 */  0x8A, 0x40, 0x24, 0x69, 0x0E, 0x60, 0x30, 0x1A,  // .@$i.`0.
                /* 0030 */  0x40, 0x24, 0x09, 0x42, 0xBC, 0x22, 0x20, 0x42,  // @$.B." B
                /* 0038 */  0x20, 0x24, 0x51, 0x80, 0x79, 0x01, 0xBA, 0x05,  //  $Q.y...
                /* 0040 */  0x18, 0x16, 0x60, 0x5B, 0x80, 0x69, 0x01, 0x8E,  // ..`[.i..
                /* 0048 */  0x81, 0xD4, 0xBF, 0x3F, 0xB4, 0x40, 0x24, 0x02,  // ...?.@$.
                /* 0050 */  0x92, 0x4A, 0x81, 0x90, 0x50, 0x01, 0xCA, 0x05,  // .J..P...
                /* 0058 */  0xF8, 0x16, 0xA0, 0x1D, 0x51, 0x92, 0x05, 0x58,  // ....Q..X
                /* 0060 */  0x86, 0x11, 0x81, 0xBD, 0x0A, 0xB0, 0x29, 0xC0,  // ......).
                /* 0068 */  0x24, 0x1A, 0x82, 0xA0, 0x9C, 0x61, 0xA0, 0xE0,  // $....a..
                /* 0070 */  0x0D, 0xC8, 0x06, 0xC1, 0x44, 0x0F, 0x02, 0x25,  // ....D..%
                /* 0078 */  0x66, 0x34, 0x64, 0x06, 0x9D, 0xCF, 0x45, 0xF0,  // f4d...E.
                /* 0080 */  0x27, 0x51, 0xB8, 0x00, 0xE9, 0x18, 0x1A, 0xC1,  // 'Q......
                /* 0088 */  0x11, 0x25, 0xE8, 0x70, 0x48, 0x92, 0x8D, 0x20,  // .%.pH.. 
                /* 0090 */  0x41, 0x02, 0x14, 0xC2, 0xCB, 0xA7, 0x00, 0xA7,  // A.......
                /* 0098 */  0x28, 0xD2, 0x28, 0xC0, 0x3A, 0x9C, 0x60, 0x63,  // (.(.:.`c
                /* 00A0 */  0x72, 0xA4, 0x28, 0x07, 0x71, 0x36, 0x06, 0xEB,  // r.(.q6..
                /* 00A8 */  0x19, 0x45, 0x40, 0xA7, 0xC2, 0x09, 0xA2, 0x1F,  // .E@.....
                /* 00B0 */  0x0A, 0x46, 0x06, 0x84, 0x3C, 0x0A, 0xB0, 0x8A,  // .F..<...
                /* 00B8 */  0xA6, 0xB9, 0x24, 0xB0, 0x7B, 0x01, 0x06, 0x67,  // ..$.{..g
                /* 00C0 */  0x21, 0x84, 0x23, 0x29, 0x4C, 0x80, 0x66, 0x01,  // !.#)L.f.
                /* 00C8 */  0xD6, 0x04, 0x28, 0x16, 0x60, 0x4B, 0x80, 0xB8,  // ..(.`K..
                /* 00D0 */  0x21, 0x69, 0x32, 0x8D, 0xA1, 0x08, 0x22, 0xC2,  // !i2...".
                /* 00D8 */  0x71, 0x46, 0x31, 0x66, 0xC0, 0x08, 0x46, 0x39,  // qF1f..F9
                /* 00E0 */  0x9A, 0xE6, 0x40, 0xA4, 0x4D, 0x80, 0x32, 0x10,  // ..@.M.2.
                /* 00E8 */  0xA1, 0xC5, 0x62, 0x08, 0xB6, 0x3F, 0x08, 0x32,  // ..b..?.2
                /* 00F0 */  0x72, 0xDC, 0x11, 0xC0, 0xE3, 0x39, 0xA9, 0xC8,  // r....9..
                /* 00F8 */  0x07, 0xE8, 0x51, 0x24, 0xF0, 0xA8, 0xCE, 0xAF,  // ..Q$....
                /* 0100 */  0x5C, 0x5C, 0x89, 0x47, 0x15, 0xC6, 0x09, 0x24,  // \\.G...$
                /* 0108 */  0x70, 0xB0, 0x13, 0x81, 0x24, 0x80, 0x28, 0x12,  // p...$.(.
                /* 0110 */  0x3C, 0x6A, 0xE0, 0x09, 0x8E, 0xDF, 0x43, 0x3B,  // <j....C;
                /* 0118 */  0xCE, 0xA3, 0x3E, 0xCE, 0x13, 0x38, 0x57, 0x8F,  // ..>..8W.
                /* 0120 */  0xA0, 0xCE, 0x53, 0x01, 0x19, 0x03, 0xC3, 0x4A,  // ..S....J
                /* 0128 */  0xF0, 0x87, 0xE0, 0x93, 0x00, 0xDE, 0x35, 0xA0,  // ......5.
                /* 0130 */  0xFE, 0xFF, 0xF7, 0x83, 0x27, 0x01, 0x36, 0xE4,  // ....'.6.
                /* 0138 */  0x70, 0x98, 0xF1, 0x7A, 0xE2, 0xC7, 0xE9, 0x51,  // p..z...Q
                /* 0140 */  0x1E, 0x09, 0x83, 0x38, 0xA2, 0x83, 0xC3, 0x0E,  // ...8....
                /* 0148 */  0xF9, 0x64, 0x8E, 0xAC, 0x54, 0x01, 0x66, 0x4F,  // .d..T.fO
                /* 0150 */  0x08, 0xB2, 0x08, 0xA4, 0xF1, 0xF8, 0x50, 0xE0,  // ......P.
                /* 0158 */  0xF9, 0xBC, 0x05, 0x24, 0xB0, 0xFC, 0x41, 0xA0,  // ...$..A.
                /* 0160 */  0x46, 0x66, 0x68, 0x8F, 0xFB, 0x91, 0x80, 0x1D,  // Ffh.....
                /* 0168 */  0x16, 0x0E, 0x8B, 0x89, 0x3D, 0x4C, 0xD0, 0xF1,  // ....=L..
                /* 0170 */  0x80, 0xFF, 0x56, 0x70, 0xFC, 0x11, 0x4E, 0xDF,  // ..Vp..N.
                /* 0178 */  0xF3, 0x35, 0x41, 0x81, 0xC0, 0xE8, 0x01, 0xD9,  // .5A.....
                /* 0180 */  0xAF, 0x00, 0x84, 0xE0, 0x65, 0x8E, 0x48, 0xC7,  // ....e.H.
                /* 0188 */  0x80, 0x08, 0x09, 0xDE, 0x1B, 0xE2, 0x1E, 0xF8,  // ........
                /* 0190 */  0xF3, 0x02, 0x83, 0x08, 0xF3, 0xD6, 0xE0, 0x11,  // ........
                /* 0198 */  0x1C, 0x0D, 0x13, 0x79, 0x98, 0x40, 0x0F, 0x80,  // ...y.@..
                /* 01A0 */  0x9F, 0x02, 0xE2, 0x87, 0x3D, 0x99, 0x03, 0x38,  // ....=..8
                /* 01A8 */  0x9C, 0x28, 0xE7, 0x70, 0x3C, 0xBE, 0x42, 0x18,  // .(.p<.B.
                /* 01B0 */  0x21, 0xFE, 0xB3, 0xC1, 0x73, 0x86, 0xAF, 0x0D,  // !...s...
                /* 01B8 */  0x27, 0xF4, 0x18, 0x71, 0x4A, 0x2F, 0x03, 0x26,  // '..qJ/.&
                /* 01C0 */  0x18, 0xF9, 0x35, 0xA0, 0x53, 0x88, 0xE3, 0x82,  // ..5.S...
                /* 01C8 */  0xC8, 0xC6, 0x4A, 0x7D, 0xE8, 0xA0, 0x71, 0x57,  // ..J}..qW
                /* 01D0 */  0xAB, 0x01, 0xE1, 0xB0, 0x9F, 0x2C, 0x4C, 0x30,  // .....,L0
                /* 01D8 */  0x24, 0x98, 0x4E, 0x24, 0x3C, 0x1E, 0x85, 0x44,  // $.N$<..D
                /* 01E0 */  0xD0, 0x68, 0x3C, 0x06, 0x77, 0xEC, 0x83, 0x09,  // .h<.w...
                /* 01E8 */  0x05, 0x31, 0xA0, 0x33, 0x41, 0xC8, 0xC8, 0x28,  // .1.3A..(
                /* 01F0 */  0xE8, 0x41, 0x80, 0xCF, 0xE0, 0xA5, 0xE2, 0x91,  // .A......
                /* 01F8 */  0xC1, 0xA7, 0x8E, 0x28, 0x27, 0xE4, 0x04, 0x10,  // ...('...
                /* 0200 */  0x3A, 0x3C, 0x78, 0x84, 0x3E, 0x08, 0xF0, 0x13,  // :<x.>...
                /* 0208 */  0x8A, 0x6F, 0x06, 0xC6, 0xF6, 0xA1, 0xC1, 0xFF,  // .o......
                /* 0210 */  0xFF, 0x7F, 0x0A, 0x1D, 0x2C, 0x19, 0xD3, 0x59,  // ....,..Y
                /* 0218 */  0x3E, 0x15, 0xF8, 0x00, 0x60, 0x35, 0x70, 0x28,  // >...`5p(
                /* 0220 */  0x68, 0x1F, 0x39, 0xF8, 0xBD, 0x45, 0x77, 0x02,  // h.9..Ew.
                /* 0228 */  0xE8, 0xE3, 0x39, 0x10, 0x0F, 0xE8, 0x98, 0x12,  // ..9.....
                /* 0230 */  0xD4, 0x77, 0x25, 0x00, 0x05, 0x90, 0x0F, 0x01,  // .w%.....
                /* 0238 */  0x56, 0x7A, 0x0F, 0xA0, 0x53, 0x08, 0x11, 0x26,  // Vz..S..&
                /* 0240 */  0x9A, 0xD1, 0xF9, 0x71, 0xC3, 0x43, 0xE6, 0x51,  // ...q.C.Q
                /* 0248 */  0x60, 0x34, 0x64, 0x83, 0x78, 0x60, 0x8E, 0x03,  // `4d.x`..
                /* 0250 */  0x21, 0x27, 0x47, 0x09, 0xD4, 0x58, 0x3D, 0xA1,  // !'G..X=.
                /* 0258 */  0xCE, 0x6E, 0x23, 0x1A, 0xC1, 0x9B, 0x8B, 0x0F,  // .n#.....
                /* 0260 */  0x06, 0xEF, 0x12, 0x3E, 0x26, 0xB0, 0x61, 0x3F,  // ...>&.a?
                /* 0268 */  0x72, 0xC0, 0x3A, 0xB3, 0x78, 0xF0, 0x9E, 0x88,  // r.:.x...
                /* 0270 */  0x47, 0x8D, 0x1F, 0x2E, 0x1F, 0x8D, 0x8F, 0x14,  // G.......
                /* 0278 */  0xF0, 0xA7, 0xCB, 0xE7, 0xE3, 0xE1, 0x91, 0x93,  // ........
                /* 0280 */  0x01, 0xFA, 0xBC, 0xE0, 0x93, 0x81, 0xCF, 0x0B,  // ........
                /* 0288 */  0x07, 0xE3, 0x9B, 0x01, 0x27, 0x18, 0xE2, 0x68,  // ....'..h
                /* 0290 */  0x40, 0x87, 0x05, 0xAE, 0xB3, 0x01, 0x5F, 0x96,  // @....._.
                /* 0298 */  0x47, 0x07, 0xEF, 0x8C, 0x44, 0x46, 0x07, 0xFD,  // G...DF..
                /* 02A0 */  0xFF, 0x7F, 0x37, 0xC0, 0x1D, 0x3F, 0xC0, 0x71,  // ..7..?.q
                /* 02A8 */  0x37, 0x80, 0x09, 0x8F, 0x39, 0x59, 0xD8, 0xC2,  // 7...9Y..
                /* 02B0 */  0x78, 0xE8, 0xB0, 0xF8, 0xB1, 0xC0, 0x77, 0x8D,  // x.....w.
                /* 02B8 */  0x37, 0x27, 0xDF, 0x45, 0x70, 0x63, 0x7A, 0x2D,  // 7'.Epcz-
                /* 02C0 */  0xF0, 0x39, 0xC0, 0xB0, 0x1E, 0x2F, 0x87, 0x35,  // .9.../.5
                /* 02C8 */  0x5A, 0xD8, 0x13, 0x7F, 0x4A, 0xF1, 0x0D, 0xC7,  // Z...J...
                /* 02D0 */  0x13, 0xF3, 0x0D, 0x81, 0x9D, 0x6D, 0xC0, 0x01,  // .....m..
                /* 02D8 */  0x88, 0xF7, 0x7E, 0xAD, 0x21, 0x13, 0x30, 0x20,  // ..~.!.0 
                /* 02E0 */  0x9B, 0xE3, 0x43, 0x14, 0x58, 0x8E, 0x06, 0xC7,  // ..C.X...
                /* 02E8 */  0x79, 0x6E, 0x2F, 0x4E, 0xFC, 0x0C, 0x05, 0x83,  // yn/N....
                /* 02F0 */  0xC0, 0x31, 0x9E, 0x07, 0x06, 0xF1, 0x0A, 0x25,  // .1.....%
                /* 02F8 */  0x1C, 0x06, 0x75, 0xF6, 0x02, 0xDE, 0x27, 0x0D,  // ..u...'.
                /* 0300 */  0x8F, 0x13, 0x1C, 0xD3, 0x7C, 0xEC, 0x30, 0xCA,  // ....|.0.
                /* 0308 */  0xFF, 0x3F, 0xD2, 0x61, 0xBE, 0x1C, 0x45, 0xF1,  // .?.a..E.
                /* 0310 */  0x5C, 0x3C, 0xAE, 0x47, 0x01, 0x06, 0x75, 0xF4,  // \<.G..u.
                /* 0318 */  0x2F, 0x06, 0xB1, 0x8C, 0x72, 0x6E, 0xB1, 0x0E,  // /...rn..
                /* 0320 */  0x20, 0xCE, 0xA3, 0x83, 0x91, 0x02, 0x05, 0x39,  //  ......9
                /* 0328 */  0x88, 0x18, 0x81, 0x7C, 0xAE, 0xF0, 0xE9, 0x0B,  // ...|....
                /* 0330 */  0x5C, 0x33, 0x78, 0xFA, 0x02, 0xC6, 0x91, 0x5F,  // \3x...._
                /* 0338 */  0x1C, 0x3A, 0x13, 0xF8, 0xF4, 0x05, 0xF0, 0xE2,  // .:......
                /* 0340 */  0xFF, 0x7F, 0xFA, 0xE2, 0xD1, 0x8F, 0x40, 0xE8,  // ......@.
                /* 0348 */  0x51, 0xF8, 0xB0, 0x11, 0xF1, 0x30, 0x4E, 0xDB,  // Q....0N.
                /* 0350 */  0x04, 0xA3, 0x0E, 0x9A, 0x8A, 0x3A, 0xA5, 0xA0,  // .....:..
                /* 0358 */  0x0E, 0x17, 0x3E, 0xA5, 0xB0, 0xC3, 0xC2, 0xEB,  // ..>.....
                /* 0360 */  0x83, 0x21, 0x1E, 0x52, 0x30, 0x07, 0x00, 0x1F,  // .!.R0...
                /* 0368 */  0x29, 0xC0, 0x31, 0x12, 0xCC, 0x69, 0xC2, 0xA7,  // ).1..i..
                /* 0370 */  0x08, 0x9F, 0x0A, 0x7D, 0x9F, 0xF0, 0xC9, 0xC3,  // ...}....
                /* 0378 */  0x30, 0x46, 0x32, 0x9E, 0x8F, 0x14, 0x78, 0xC8,  // 0F2...x.
                /* 0380 */  0x40, 0xAF, 0x14, 0xB8, 0x83, 0x11, 0x18, 0xE5,  // @.......
                /* 0388 */  0x1D, 0xDD, 0x40, 0x77, 0xFA, 0xC0, 0x9C, 0xDC,  // ..@w....
                /* 0390 */  0x80, 0xC9, 0xD5, 0xC3, 0x43, 0xE0, 0x67, 0x09,  // ....C.g.
                /* 0398 */  0x0F, 0x81, 0x0F, 0xE0, 0x11, 0xE4, 0xEC, 0x7C,  // .......|
                /* 03A0 */  0x0E, 0x3A, 0x27, 0xDC, 0x59, 0x85, 0x4F, 0x09,  // .:'.Y.O.
                /* 03A8 */  0x37, 0x00, 0x8C, 0x42, 0x9B, 0x3E, 0x35, 0x1A,  // 7..B.>5.
                /* 03B0 */  0xB5, 0x6A, 0x50, 0xA6, 0x46, 0x99, 0x06, 0xB5,  // .jP.F...
                /* 03B8 */  0xFA, 0x54, 0x6A, 0xCC, 0xD8, 0xC1, 0xC1, 0xA2,  // .Tj.....
                /* 03C0 */  0xDE, 0x0E, 0x3A, 0x1C, 0x38, 0x12, 0x08, 0x15,  // ..:.8...
                /* 03C8 */  0x73, 0xB2, 0x91, 0x11, 0x10, 0x29, 0x03, 0x11,  // s....)..
                /* 03D0 */  0x90, 0xFF, 0xFF, 0x42, 0x9E, 0x46, 0x02, 0xB2,  // ...B.F..
                /* 03D8 */  0x2C, 0x10, 0x01, 0x39, 0x22, 0x10, 0x0D, 0x0C,  // ,..9"...
                /* 03E0 */  0x44, 0xE5, 0x9A, 0x00, 0x61, 0x61, 0x41, 0x68,  // D...aaAh
                /* 03E8 */  0x4C, 0x15, 0x20, 0xEC, 0xFF, 0x0F               // L. ...
            })
            Method (WMAA, 3, Serialized)
            {
                Acquire (MUTW, 0xFFFF)
                WMIC++
                Name (WMRP, Package (0x02)
                {
                    Buffer (0x04){}, 
                    Buffer (0x0100){}
                })
                Local0 = Arg2
                CreateByteField (Local0, Zero, MFID)
                CreateByteField (Local0, One, SFID)
                Local1 = DerefOf (WMRP [One])
                CreateByteField (Local1, Zero, STAT)
                STAT = One
                If ((WMIC == 0x02))
                {
                    WMIC = Zero
                    Switch (MFID)
                    {
                        Case (One)
                        {
                            Switch (SFID)
                            {
                                Case (One)
                                {
                                    Local1 = GVER (Local0)
                                }

                            }
                        }
                        Case (0x02)
                        {
                            Switch (SFID)
                            {
                                Case (One)
                                {
                                    Local1 = GTSI (Local0)
                                }
                                Case (0x02)
                                {
                                    Local1 = GTMP (Local0)
                                }
                                Case (0x03)
                                {
                                    Local1 = STMT (Local0)
                                }
                                Case (0x04)
                                {
                                    Local1 = GPSI (Local0)
                                }
                                Case (0x05)
                                {
                                    Local1 = GPCI (Local0)
                                }
                                Case (0x06)
                                {
                                    Local1 = GLIV (Local0)
                                }
                                Case (0x07)
                                {
                                    Local1 = SLIV (Local0)
                                }
                                Case (0x08)
                                {
                                    Local1 = GFNS (Local0)
                                }
                                Case (0x09)
                                {
                                    Local1 = GCVA (Local0)
                                }
                                Case (0x0B)
                                {
                                    Local1 = STMP (Local0)
                                }
                                Case (0x0C)
                                {
                                    Local1 = GBAI (Local0)
                                }
                                Case (0x0D)
                                {
                                    Local1 = GCII (Local0)
                                }
                                Case (0x0E)
                                {
                                    Local1 = GADI (Local0)
                                }
                                Case (0x0F)
                                {
                                    Local1 = GTPS (Local0)
                                }
                                Case (0x10)
                                {
                                    Local1 = STPS (Local0)
                                }

                            }
                        }
                        Case (0x03)
                        {
                            Switch (SFID)
                            {
                                Case (0x0C)
                                {
                                    Local1 = GCPL (Local0)
                                }
                                Case (0x0D)
                                {
                                    Local1 = SPLV (Local0)
                                }
                                Case (0x0E)
                                {
                                    Local1 = GODP (Local0)
                                }
                                Case (0x0F)
                                {
                                    Local1 = SODP (Local0)
                                }
                                Case (0x10)
                                {
                                    Local1 = SBTT (Local0)
                                }
                                Case (0x11)
                                {
                                    Local1 = GBTT (Local0)
                                }
                                Case (0x12)
                                {
                                    Local1 = SBAD (Local0)
                                }
                                Case (0x13)
                                {
                                    Local1 = GBAD (Local0)
                                }
                                Case (0x14)
                                {
                                    Local1 = GAIT (Local0)
                                }
                                Case (0x15)
                                {
                                    Local1 = SBCM (Local0)
                                }
                                Case (0x16)
                                {
                                    Local1 = GBCM (Local0)
                                }

                            }
                        }
                        Case (0x04)
                        {
                            Switch (SFID)
                            {
                                Case (0x06)
                                {
                                    Local1 = GFRS (Local0)
                                }
                                Case (0x07)
                                {
                                    Local1 = SFRS (Local0)
                                }
                                Case (0x0B)
                                {
                                    Local1 = SMLS (Local0)
                                }
                                Case (0x0C)
                                {
                                    Local1 = GFNM (Local0)
                                }
                                Case (0x0D)
                                {
                                    Local1 = SFNM (Local0)
                                }
                                Case (0x0E)
                                {
                                    Local1 = GTUB (Local0)
                                }
                                Case (0x0F)
                                {
                                    Local1 = STUB (Local0)
                                }
                                Case (0x10)
                                {
                                    Local1 = GWKM (Local0)
                                }
                                Case (0x11)
                                {
                                    Local1 = SWKM (Local0)
                                }
                                Case (0x12)
                                {
                                    Local1 = GPFM (Local0)
                                }
                                Case (0x13)
                                {
                                    Local1 = SPFM (Local0)
                                }
                                Case (0x14)
                                {
                                    Local1 = SFNS (Local0)
                                }

                            }
                        }
                        Case (0x05)
                        {
                            Switch (SFID)
                            {
                                Case (One)
                                {
                                    Local1 = GSTP (Local0)
                                }
                                Case (0x02)
                                {
                                    Local1 = SSTP (Local0)
                                }

                            }
                        }
                        Case (0x06)
                        {
                            Switch (SFID)
                            {
                                Case (One)
                                {
                                    Local1 = SLGO (Local0)
                                }
                                Case (0x02)
                                {
                                    Local1 = GLGO (Local0)
                                }
                                Case (0x03)
                                {
                                    Local1 = SLOG (Local0)
                                }
                                Case (0x04)
                                {
                                    Local1 = GLOG (Local0)
                                }
                                Case (0x05)
                                {
                                    Local1 = SLED (Local0)
                                }
                                Case (0x06)
                                {
                                    Local1 = GLED (Local0)
                                }
                                Case (0x07)
                                {
                                    Local1 = GNTB (Local0)
                                }
                                Case (0x08)
                                {
                                    Local1 = SNTB (Local0)
                                }
                                Case (0x09)
                                {
                                    Local1 = SSWL (Local0)
                                }
                                Case (0x0A)
                                {
                                    Local1 = GSWL (Local0)
                                }
                                Case (0x0B)
                                {
                                    Local1 = SECL (Local0)
                                }
                                Case (0x0C)
                                {
                                    Local1 = GECL (Local0)
                                }
                                Case (0x0D)
                                {
                                    Local1 = SPDV (Local0)
                                }
                                Case (0x0E)
                                {
                                    Local1 = GPDV (Local0)
                                }
                                Case (0x0F)
                                {
                                    Local1 = SOSF (Local0)
                                }
                                Case (0x10)
                                {
                                    Local1 = GOSF (Local0)
                                }
                                Case (0x11)
                                {
                                    Local1 = SKBT (Local0)
                                }
                                Case (0x12)
                                {
                                    Local1 = GKBT (Local0)
                                }
                                Case (0x13)
                                {
                                    Local1 = GKBM (Local0)
                                }
                                Case (0x14)
                                {
                                    Local1 = SKBM (Local0)
                                }
                                Case (0x15)
                                {
                                    Local1 = SKBL (Local0)
                                }
                                Case (0x16)
                                {
                                    Local1 = GECV (Local0)
                                }
                                Case (0x17)
                                {
                                    Local1 = SECV (Local0)
                                }
                                Case (0x18)
                                {
                                    Local1 = HADS (Local0)
                                }
                                Case (0x19)
                                {
                                    Local1 = GDXD (Local0)
                                }
                                Case (0x1C)
                                {
                                    Local1 = GBTM (Local0)
                                }
                                Case (0x1F)
                                {
                                    Local1 = GFCC (Local0)
                                }
                                Case (0x20)
                                {
                                    Local1 = DerefOf (WMRP [One])
                                    \_SB.PC00.LPCB.EC0.WMEN = 0x02B0
                                    Notify (\_SB.WMI1, 0xA0) // Device-Specific
                                }
                                Case (0x25)
                                {
                                    Local1 = SAOP (Local0)
                                }
                                Case (0x26)
                                {
                                    Local1 = GAOP (Local0)
                                }

                            }
                        }
                        Case (0x07)
                        {
                            Switch (SFID)
                            {
                                Case (0x05)
                                {
                                    Local1 = ISIA (Local0)
                                }

                            }
                        }

                    }
                }

                WMRP [One] = Local1
                Release (MUTW)
                Return (WMRP) /* \_SB_.WMI1.WMAA.WMRP */
            }

            Method (_WED, 1, NotSerialized)  // _Wxx: Wake Event, xx=0x00-0xFF
            {
                Return (\_SB.PC00.LPCB.EC0.WMEN) /* External reference */
            }
        }
    }
}

