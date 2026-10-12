/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20250404 (64-bit version)
 * Copyright (c) 2000 - 2025 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of /work/input/reg_SSDT_HONOR_DptfTabl_00001000.bin
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x00004B87 (19335)
 *     Revision         0x02
 *     Checksum         0xFB
 *     OEM ID           "HONOR"
 *     OEM Table ID     "DptfTabl"
 *     OEM Revision     0x00001000 (4096)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20200717 (538969879)
 */
DefinitionBlock ("", "SSDT", 2, "HONOR", "DptfTabl", 0x00001000)
{
    External (_SB_.AAC0, FieldUnitObj)
    External (_SB_.ACRT, FieldUnitObj)
    External (_SB_.APSV, FieldUnitObj)
    External (_SB_.CBMI, FieldUnitObj)
    External (_SB_.CFGD, FieldUnitObj)
    External (_SB_.CLVL, FieldUnitObj)
    External (_SB_.CPPC, FieldUnitObj)
    External (_SB_.CTC0, FieldUnitObj)
    External (_SB_.CTC1, FieldUnitObj)
    External (_SB_.CTC2, FieldUnitObj)
    External (_SB_.OSCP, IntObj)
    External (_SB_.PAGD, DeviceObj)
    External (_SB_.PAGD._PUR, PkgObj)
    External (_SB_.PAGD._STA, MethodObj)    // 0 Arguments
    External (_SB_.PC00, DeviceObj)
    External (_SB_.PC00.LPCB.EC0_, DeviceObj)
    External (_SB_.PC00.LPCB.EC0_.BTTL, FieldUnitObj)
    External (_SB_.PC00.LPCB.EC0_.CNTC, FieldUnitObj)
    External (_SB_.PC00.LPCB.EC0_.LPL1, FieldUnitObj)
    External (_SB_.PC00.LPCB.EC0_.PCHT, FieldUnitObj)
    External (_SB_.PC00.LPCB.EC0_.PG1D, FieldUnitObj)
    External (_SB_.PC00.LPCB.EC0_.PG1U, FieldUnitObj)
    External (_SB_.PC00.LPCB.EC0_.PG2D, FieldUnitObj)
    External (_SB_.PC00.LPCB.EC0_.PG2U, FieldUnitObj)
    External (_SB_.PC00.LPCB.EC0_.PG3D, FieldUnitObj)
    External (_SB_.PC00.LPCB.EC0_.PG3U, FieldUnitObj)
    External (_SB_.PC00.LPCB.EC0_.PG4D, FieldUnitObj)
    External (_SB_.PC00.LPCB.EC0_.PG4U, FieldUnitObj)
    External (_SB_.PC00.LPCB.EC0_.STM0, FieldUnitObj)
    External (_SB_.PC00.LPCB.EC0_.SYST, FieldUnitObj)
    External (_SB_.PC00.LPCB.EC0_.TDPS, FieldUnitObj)
    External (_SB_.PC00.LPCB.EC0_.TNTC, FieldUnitObj)
    External (_SB_.PC00.LPCB.EC0_.VGET, FieldUnitObj)
    External (_SB_.PC00.MC__.MHBR, FieldUnitObj)
    External (_SB_.PC00.TCPU, DeviceObj)
    External (_SB_.PL10, FieldUnitObj)
    External (_SB_.PL11, FieldUnitObj)
    External (_SB_.PL12, FieldUnitObj)
    External (_SB_.PL20, FieldUnitObj)
    External (_SB_.PL21, FieldUnitObj)
    External (_SB_.PL22, FieldUnitObj)
    External (_SB_.PLW0, FieldUnitObj)
    External (_SB_.PLW1, FieldUnitObj)
    External (_SB_.PLW2, FieldUnitObj)
    External (_SB_.PR00, ProcessorObj)
    External (_SB_.PR00._PSS, MethodObj)    // 0 Arguments
    External (_SB_.PR00._TPC, IntObj)
    External (_SB_.PR00._TSD, MethodObj)    // 0 Arguments
    External (_SB_.PR00._TSS, MethodObj)    // 0 Arguments
    External (_SB_.PR00.LPSS, PkgObj)
    External (_SB_.PR00.TPSS, PkgObj)
    External (_SB_.PR00.TSMC, PkgObj)
    External (_SB_.PR00.TSMF, PkgObj)
    External (_SB_.PR01, ProcessorObj)
    External (_SB_.PR02, ProcessorObj)
    External (_SB_.PR03, ProcessorObj)
    External (_SB_.PR04, ProcessorObj)
    External (_SB_.PR05, ProcessorObj)
    External (_SB_.PR06, ProcessorObj)
    External (_SB_.PR07, ProcessorObj)
    External (_SB_.PR08, ProcessorObj)
    External (_SB_.PR09, ProcessorObj)
    External (_SB_.PR10, ProcessorObj)
    External (_SB_.PR11, ProcessorObj)
    External (_SB_.PR12, ProcessorObj)
    External (_SB_.PR13, ProcessorObj)
    External (_SB_.PR14, ProcessorObj)
    External (_SB_.PR15, ProcessorObj)
    External (_SB_.PR16, ProcessorObj)
    External (_SB_.PR17, ProcessorObj)
    External (_SB_.PR18, ProcessorObj)
    External (_SB_.PR19, ProcessorObj)
    External (_SB_.PR20, ProcessorObj)
    External (_SB_.PR21, ProcessorObj)
    External (_SB_.PR22, ProcessorObj)
    External (_SB_.PR23, ProcessorObj)
    External (_SB_.PR24, ProcessorObj)
    External (_SB_.PR25, ProcessorObj)
    External (_SB_.PR26, ProcessorObj)
    External (_SB_.PR27, ProcessorObj)
    External (_SB_.PR28, ProcessorObj)
    External (_SB_.PR29, ProcessorObj)
    External (_SB_.PR30, ProcessorObj)
    External (_SB_.PR31, ProcessorObj)
    External (_SB_.TAR0, FieldUnitObj)
    External (_SB_.TAR1, FieldUnitObj)
    External (_SB_.TAR2, FieldUnitObj)
    External (_TZ_.ETMD, IntObj)
    External (ACTT, IntObj)
    External (ATPC, IntObj)
    External (BATR, IntObj)
    External (CHGE, IntObj)
    External (CRTT, IntObj)
    External (DCFE, IntObj)
    External (DPTF, IntObj)
    External (FND1, IntObj)
    External (FND2, IntObj)
    External (FND3, IntObj)
    External (HIDW, MethodObj)    // 4 Arguments
    External (HIWC, MethodObj)    // 1 Arguments
    External (IN34, IntObj)
    External (ODV0, IntObj)
    External (ODV1, IntObj)
    External (ODV2, IntObj)
    External (ODV3, IntObj)
    External (ODV4, IntObj)
    External (ODV5, IntObj)
    External (PCHE, FieldUnitObj)
    External (PF00, IntObj)
    External (PLID, IntObj)
    External (PNHM, IntObj)
    External (PPPR, IntObj)
    External (PPSZ, IntObj)
    External (PSVT, IntObj)
    External (PTPC, IntObj)
    External (PWRE, IntObj)
    External (PWRS, IntObj)
    External (S1AT, IntObj)
    External (S1CT, IntObj)
    External (S1DE, IntObj)
    External (S1HT, IntObj)
    External (S1PT, IntObj)
    External (S1S3, IntObj)
    External (S2AT, IntObj)
    External (S2CT, IntObj)
    External (S2DE, IntObj)
    External (S2HT, IntObj)
    External (S2PT, IntObj)
    External (S2S3, IntObj)
    External (S3AT, IntObj)
    External (S3CT, IntObj)
    External (S3DE, IntObj)
    External (S3HT, IntObj)
    External (S3PT, IntObj)
    External (S3S3, IntObj)
    External (S4AT, IntObj)
    External (S4CT, IntObj)
    External (S4DE, IntObj)
    External (S4HT, IntObj)
    External (S4PT, IntObj)
    External (S4S3, IntObj)
    External (S5AT, IntObj)
    External (S5CT, IntObj)
    External (S5DE, IntObj)
    External (S5HT, IntObj)
    External (S5PT, IntObj)
    External (S5S3, IntObj)
    External (S6DE, IntObj)
    External (S6P2, IntObj)
    External (SADE, IntObj)
    External (SSP1, IntObj)
    External (SSP2, IntObj)
    External (SSP3, IntObj)
    External (SSP4, IntObj)
    External (SSP5, IntObj)
    External (TCNT, IntObj)
    External (TSOD, IntObj)

    Scope (\_SB)
    {
        Device (IETM)
        {
            Method (GHID, 1, Serialized)
            {
                If ((Arg0 == "IETM"))
                {
                    Return ("INTC1041")
                }

                If ((Arg0 == "SEN1"))
                {
                    Return ("INTC1046")
                }

                If ((Arg0 == "SEN2"))
                {
                    Return ("INTC1046")
                }

                If ((Arg0 == "SEN3"))
                {
                    Return ("INTC1046")
                }

                If ((Arg0 == "SEN4"))
                {
                    Return ("INTC1046")
                }

                If ((Arg0 == "SEN5"))
                {
                    Return ("INTC1046")
                }

                If ((Arg0 == "SEN6"))
                {
                    Return ("INTC1046")
                }

                If ((Arg0 == "SEN7"))
                {
                    Return ("INTC1046")
                }

                If ((Arg0 == "TPCH"))
                {
                    Return ("INTC1049")
                }

                If ((Arg0 == "TFN1"))
                {
                    Return ("INTC1048")
                }

                If ((Arg0 == "TFN2"))
                {
                    Return ("INTC1048")
                }

                If ((Arg0 == "TFN3"))
                {
                    Return ("INTC1048")
                }

                If ((Arg0 == "TPWR"))
                {
                    Return ("INTC1060")
                }

                If ((Arg0 == "1"))
                {
                    Return ("INTC1061")
                }

                If ((Arg0 == "CHRG"))
                {
                    Return ("INTC1046")
                }

                Return ("XXXX9999")
            }

            Name (_UID, "IETM")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.IETM.GHID (_UID))
            }

            Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
            {
                If (CondRefOf (HIWC))
                {
                    If (HIWC (Arg0))
                    {
                        If (CondRefOf (HIDW))
                        {
                            Return (HIDW (Arg0, Arg1, Arg2, Arg3))
                        }
                    }
                }

                Return (Buffer (One)
                {
                     0x00                                             // .
                })
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (((\DPTF == One) && (\IN34 == One)))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (PTRP, Zero)
            Name (PSEM, Zero)
            Name (ATRP, Zero)
            Name (ASEM, Zero)
            Name (YTRP, Zero)
            Name (YSEM, Zero)
            Method (_OSC, 4, Serialized)  // _OSC: Operating System Capabilities
            {
                CreateDWordField (Arg3, Zero, STS1)
                CreateDWordField (Arg3, 0x04, CAP1)
                If ((CAP1 & One))
                {
                    \_SB.PC00.LPCB.EC0.LPL1 = Zero
                    Sleep (0x10)
                    \_SB.PC00.LPCB.EC0.TDPS = One
                }

                If ((Arg1 != One))
                {
                    STS1 &= 0xFFFFFF00
                    STS1 |= 0x0A
                    Return (Arg3)
                }

                If ((Arg2 != 0x02))
                {
                    STS1 &= 0xFFFFFF00
                    STS1 |= 0x02
                    Return (Arg3)
                }

                If (CondRefOf (\_SB.APSV))
                {
                    If ((PSEM == Zero))
                    {
                        PSEM = One
                        PTRP = \_SB.APSV /* External reference */
                    }
                }

                If (CondRefOf (\_SB.AAC0))
                {
                    If ((ASEM == Zero))
                    {
                        ASEM = One
                        ATRP = \_SB.AAC0 /* External reference */
                    }
                }

                If (CondRefOf (\_SB.ACRT))
                {
                    If ((YSEM == Zero))
                    {
                        YSEM = One
                        YTRP = \_SB.ACRT /* External reference */
                    }
                }

                If ((Arg0 == ToUUID ("b23ba85d-c8b7-3542-88de-8de2ffcfd698") /* Unknown UUID */))
                {
                    If (~(STS1 & One))
                    {
                        If ((CAP1 & One))
                        {
                            If ((CAP1 & 0x02))
                            {
                                \_SB.AAC0 = 0x6E
                                \_TZ.ETMD = Zero
                            }
                            Else
                            {
                                \_SB.AAC0 = ATRP /* \_SB_.IETM.ATRP */
                                \_TZ.ETMD = One
                            }

                            If ((CAP1 & 0x04))
                            {
                                \_SB.APSV = 0x6E
                            }
                            Else
                            {
                                \_SB.APSV = PTRP /* \_SB_.IETM.PTRP */
                            }

                            If ((CAP1 & 0x08))
                            {
                                \_SB.ACRT = 0xD2
                            }
                            Else
                            {
                                \_SB.ACRT = YTRP /* \_SB_.IETM.YTRP */
                            }
                        }
                        Else
                        {
                            \_SB.ACRT = YTRP /* \_SB_.IETM.YTRP */
                            \_SB.APSV = PTRP /* \_SB_.IETM.PTRP */
                            \_SB.AAC0 = ATRP /* \_SB_.IETM.ATRP */
                            \_TZ.ETMD = One
                        }
                    }

                    Return (Arg3)
                }

                Return (Arg3)
            }

            Method (DCFG, 0, NotSerialized)
            {
                Return (\DCFE) /* External reference */
            }

            Name (ODVX, Package (0x06)
            {
                Zero, 
                Zero, 
                Zero, 
                Zero, 
                Zero, 
                Zero
            })
            Method (ODVP, 0, Serialized)
            {
                ODVX [Zero] = \ODV0 /* External reference */
                ODVX [One] = \ODV1 /* External reference */
                ODVX [0x02] = \ODV2 /* External reference */
                ODVX [0x03] = \ODV3 /* External reference */
                ODVX [0x04] = \ODV4 /* External reference */
                ODVX [0x05] = \ODV5 /* External reference */
                Return (ODVX) /* \_SB_.IETM.ODVX */
            }

            Method (GDDV, 0, Serialized)
            {
                Return (Package (0x01)
                {
                    Buffer (0x10E7)
                    {
                        /* 0000 */  0xE5, 0x1F, 0x94, 0x00, 0x00, 0x00, 0x00, 0x02,  // ........
                        /* 0008 */  0x00, 0x00, 0x00, 0x40, 0x67, 0x64, 0x64, 0x76,  // ...@gddv
                        /* 0010 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                        /* 0018 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                        /* 0020 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                        /* 0028 */  0x00, 0x00, 0x00, 0x00, 0x4F, 0x45, 0x4D, 0x20,  // ....OEM 
                        /* 0030 */  0x45, 0x78, 0x70, 0x6F, 0x72, 0x74, 0x65, 0x64,  // Exported
                        /* 0038 */  0x20, 0x44, 0x61, 0x74, 0x61, 0x56, 0x61, 0x75,  //  DataVau
                        /* 0040 */  0x6C, 0x74, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // lt......
                        /* 0048 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                        /* 0050 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                        /* 0058 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                        /* 0060 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                        /* 0068 */  0x00, 0x00, 0x00, 0x00, 0xC7, 0x0F, 0x93, 0x19,  // ........
                        /* 0070 */  0xF1, 0xCA, 0x83, 0x59, 0x23, 0x86, 0x40, 0xF3,  // ...Y#.@.
                        /* 0078 */  0x21, 0x32, 0xA9, 0x30, 0x83, 0x88, 0xBD, 0xDE,  // !2.0....
                        /* 0080 */  0xDD, 0xCB, 0xB8, 0x67, 0xC3, 0xF8, 0x89, 0xE1,  // ...g....
                        /* 0088 */  0x79, 0xEE, 0xE9, 0xF4, 0x53, 0x10, 0x00, 0x00,  // y...S...
                        /* 0090 */  0x52, 0x45, 0x50, 0x4F, 0x5D, 0x00, 0x00, 0x00,  // REPO]...
                        /* 0098 */  0x01, 0xAC, 0x57, 0x01, 0x00, 0x00, 0x00, 0x00,  // ..W.....
                        /* 00A0 */  0x00, 0x00, 0x72, 0x87, 0xCD, 0xFF, 0x6D, 0x24,  // ..r...m$
                        /* 00A8 */  0x47, 0xDB, 0x3D, 0x24, 0x92, 0xB4, 0x16, 0x6F,  // G.=$...o
                        /* 00B0 */  0x45, 0xD8, 0xC3, 0xF5, 0x66, 0x14, 0x9F, 0x22,  // E...f.."
                        /* 00B8 */  0xD7, 0xF7, 0xDE, 0x67, 0x90, 0x9A, 0xA2, 0x0D,  // ...g....
                        /* 00C0 */  0x39, 0x25, 0xAD, 0xC3, 0x1A, 0xAD, 0x52, 0x0B,  // 9%....R.
                        /* 00C8 */  0x75, 0x38, 0xE1, 0xA4, 0x14, 0x43, 0xC3, 0xED,  // u8...C..
                        /* 00D0 */  0xCB, 0x68, 0x74, 0x1D, 0xF1, 0x67, 0x55, 0xA4,  // .ht..gU.
                        /* 00D8 */  0x73, 0xF5, 0x43, 0x0E, 0xBE, 0x33, 0xE6, 0x93,  // s.C..3..
                        /* 00E0 */  0xA2, 0xAF, 0x82, 0xDC, 0xA9, 0x13, 0x32, 0x1F,  // ......2.
                        /* 00E8 */  0xD6, 0xEE, 0xEF, 0x45, 0x01, 0xFA, 0x3A, 0x9D,  // ...E..:.
                        /* 00F0 */  0x2A, 0x8A, 0x77, 0xFE, 0x31, 0x45, 0x90, 0x56,  // *.w.1E.V
                        /* 00F8 */  0x08, 0x70, 0x4E, 0x94, 0x2A, 0x45, 0xF3, 0x58,  // .pN.*E.X
                        /* 0100 */  0x59, 0xC2, 0x5E, 0xB1, 0x18, 0xF3, 0xD4, 0xBF,  // Y.^.....
                        /* 0108 */  0x3D, 0x23, 0xF9, 0xF4, 0x13, 0x1F, 0x12, 0x72,  // =#.....r
                        /* 0110 */  0xAE, 0x0C, 0xAA, 0xD8, 0x26, 0xB3, 0xCC, 0x5F,  // ....&.._
                        /* 0118 */  0xFE, 0x02, 0x90, 0x52, 0x1D, 0x0A, 0xD3, 0xFB,  // ...R....
                        /* 0120 */  0x8F, 0xAE, 0x89, 0x8E, 0x79, 0xE9, 0x8F, 0x76,  // ....y..v
                        /* 0128 */  0x86, 0x93, 0xE1, 0xC3, 0x35, 0xD0, 0x1D, 0x3A,  // ....5..:
                        /* 0130 */  0x6E, 0x7F, 0xAB, 0x51, 0xAA, 0xC4, 0xBD, 0x36,  // n..Q...6
                        /* 0138 */  0xB8, 0x8B, 0x83, 0x5C, 0xE0, 0x6F, 0x19, 0xE6,  // ...\.o..
                        /* 0140 */  0x8D, 0xD9, 0x61, 0xD3, 0xA4, 0x24, 0x34, 0x34,  // ..a..$44
                        /* 0148 */  0x19, 0x0E, 0x19, 0xC9, 0xCC, 0xCD, 0xAF, 0xA9,  // ........
                        /* 0150 */  0x04, 0x97, 0xE1, 0x5E, 0x4A, 0xF3, 0xB4, 0xE0,  // ...^J...
                        /* 0158 */  0xBA, 0x91, 0xB2, 0x25, 0xF9, 0xE5, 0x9E, 0x15,  // ...%....
                        /* 0160 */  0xC4, 0xDB, 0xD4, 0xA5, 0x95, 0x77, 0xD0, 0x1F,  // .....w..
                        /* 0168 */  0xDE, 0x60, 0x66, 0xAC, 0x35, 0x2F, 0xF0, 0x48,  // .`f.5/.H
                        /* 0170 */  0xA9, 0x83, 0xDB, 0x2C, 0x8E, 0x12, 0x67, 0x30,  // ...,..g0
                        /* 0178 */  0xD5, 0xA0, 0x55, 0xC0, 0x75, 0x92, 0x53, 0x8C,  // ..U.u.S.
                        /* 0180 */  0xC2, 0x27, 0xE4, 0x0F, 0x00, 0xA7, 0xA2, 0x9B,  // .'......
                        /* 0188 */  0x68, 0x98, 0x75, 0x6F, 0x13, 0x3E, 0xD8, 0x69,  // h.uo.>.i
                        /* 0190 */  0x26, 0x4B, 0x76, 0x94, 0x08, 0x4C, 0x25, 0xF2,  // &Kv..L%.
                        /* 0198 */  0x77, 0xB9, 0x57, 0x84, 0xA2, 0x01, 0xB6, 0x8C,  // w.W.....
                        /* 01A0 */  0xFF, 0x8B, 0x98, 0x3C, 0x21, 0xAE, 0x54, 0xA3,  // ...<!.T.
                        /* 01A8 */  0x09, 0x8B, 0xE7, 0xDC, 0x78, 0x16, 0x44, 0x3D,  // ....x.D=
                        /* 01B0 */  0x04, 0xF8, 0x85, 0xEB, 0xC6, 0x01, 0x9F, 0xBB,  // ........
                        /* 01B8 */  0x47, 0xD2, 0x46, 0xB5, 0x97, 0x06, 0x67, 0x76,  // G.F...gv
                        /* 01C0 */  0x20, 0xBF, 0x2D, 0xE6, 0x45, 0x63, 0x21, 0x18,  //  .-.Ec!.
                        /* 01C8 */  0x92, 0xF3, 0x43, 0x8D, 0x16, 0xB5, 0xE7, 0x54,  // ..C....T
                        /* 01D0 */  0xCE, 0x3D, 0x83, 0x10, 0x71, 0xDA, 0x80, 0xBB,  // .=..q...
                        /* 01D8 */  0x8E, 0x4B, 0x76, 0x7C, 0xD6, 0xD8, 0x3B, 0xFA,  // .Kv|..;.
                        /* 01E0 */  0x5F, 0xCD, 0x0F, 0xDE, 0x4D, 0x39, 0xE6, 0xA3,  // _...M9..
                        /* 01E8 */  0x1B, 0x48, 0x1B, 0x09, 0x70, 0x4B, 0x00, 0xBC,  // .H..pK..
                        /* 01F0 */  0x65, 0x61, 0x20, 0xC7, 0xC8, 0x3B, 0x4A, 0xA5,  // ea ..;J.
                        /* 01F8 */  0x21, 0xF5, 0x51, 0xC6, 0x93, 0x11, 0xA5, 0x05,  // !.Q.....
                        /* 0200 */  0xD7, 0x0B, 0xF3, 0xF0, 0xDA, 0x17, 0x37, 0x9E,  // ......7.
                        /* 0208 */  0xAC, 0x90, 0x55, 0x50, 0x0B, 0x11, 0xA9, 0x4E,  // ..UP...N
                        /* 0210 */  0xC3, 0x60, 0xD0, 0x53, 0x9A, 0xB8, 0xC3, 0xCE,  // .`.S....
                        /* 0218 */  0xF4, 0x92, 0x65, 0xC9, 0x72, 0x19, 0x2C, 0xE0,  // ..e.r.,.
                        /* 0220 */  0x2A, 0x50, 0x83, 0x1C, 0xD6, 0xEE, 0x5F, 0x0C,  // *P...._.
                        /* 0228 */  0x6D, 0xFD, 0x68, 0x13, 0x27, 0xA0, 0x94, 0x00,  // m.h.'...
                        /* 0230 */  0x7F, 0x08, 0xBA, 0x83, 0x39, 0x82, 0xFE, 0x1D,  // ....9...
                        /* 0238 */  0x91, 0x10, 0xDA, 0x3E, 0x31, 0xEA, 0xA6, 0x24,  // ...>1..$
                        /* 0240 */  0xFE, 0xA1, 0x79, 0x8E, 0x12, 0x43, 0xD8, 0x38,  // ..y..C.8
                        /* 0248 */  0x65, 0xD4, 0x80, 0x87, 0xEE, 0x90, 0x49, 0x27,  // e.....I'
                        /* 0250 */  0xC7, 0xA8, 0x46, 0x5D, 0x23, 0x2B, 0xF2, 0x9A,  // ..F]#+..
                        /* 0258 */  0x08, 0xB9, 0x44, 0x4F, 0x57, 0x9C, 0x18, 0x75,  // ..DOW..u
                        /* 0260 */  0xD5, 0xCA, 0x78, 0xFB, 0x42, 0x0B, 0xCD, 0x32,  // ..x.B..2
                        /* 0268 */  0x5B, 0x76, 0x55, 0xF4, 0xED, 0x42, 0x2E, 0x76,  // [vU..B.v
                        /* 0270 */  0x38, 0x68, 0xB2, 0x17, 0x8A, 0xD8, 0x14, 0xFA,  // 8h......
                        /* 0278 */  0xC3, 0x3D, 0x7A, 0x1B, 0xD8, 0xEE, 0x27, 0x04,  // .=z...'.
                        /* 0280 */  0x5B, 0x5D, 0xC4, 0x2D, 0x66, 0xDB, 0x87, 0x45,  // [].-f..E
                        /* 0288 */  0x66, 0x42, 0x72, 0xE5, 0xB2, 0x9B, 0xD5, 0x5C,  // fBr....\
                        /* 0290 */  0x88, 0x0B, 0x0E, 0xA6, 0xAB, 0x2C, 0xD2, 0x97,  // .....,..
                        /* 0298 */  0x9D, 0x7E, 0xE8, 0x5D, 0xE5, 0x1F, 0x6B, 0x38,  // .~.]..k8
                        /* 02A0 */  0xF6, 0x73, 0xFB, 0xD4, 0xCB, 0x69, 0x5E, 0xE3,  // .s...i^.
                        /* 02A8 */  0xF3, 0x74, 0x66, 0xE6, 0x06, 0x69, 0xBE, 0xB5,  // .tf..i..
                        /* 02B0 */  0xB0, 0xE8, 0xA3, 0x63, 0xF9, 0x7A, 0xFB, 0xFD,  // ...c.z..
                        /* 02B8 */  0x13, 0xD4, 0x56, 0xB6, 0x9C, 0xC9, 0x4F, 0x27,  // ..V...O'
                        /* 02C0 */  0xAC, 0x67, 0xA3, 0xB8, 0x30, 0xCA, 0xE7, 0x20,  // .g..0.. 
                        /* 02C8 */  0x66, 0xFD, 0xF1, 0x3D, 0x53, 0xC3, 0x0E, 0xB8,  // f..=S...
                        /* 02D0 */  0xFD, 0xD9, 0x29, 0xEA, 0xC8, 0xF6, 0x0E, 0x6D,  // ..)....m
                        /* 02D8 */  0xFB, 0x08, 0x5E, 0xF0, 0xED, 0x59, 0x37, 0x0B,  // ..^..Y7.
                        /* 02E0 */  0x39, 0x5C, 0x39, 0xE3, 0xEA, 0x7F, 0x92, 0x3A,  // 9\9....:
                        /* 02E8 */  0xD0, 0x87, 0x5C, 0x15, 0xF0, 0x3C, 0x41, 0xDE,  // ..\..<A.
                        /* 02F0 */  0x91, 0xAA, 0x3A, 0x5E, 0xC5, 0xFF, 0x54, 0xEA,  // ..:^..T.
                        /* 02F8 */  0x69, 0xF4, 0x60, 0x3D, 0xC2, 0x0A, 0x10, 0xDE,  // i.`=....
                        /* 0300 */  0x2E, 0x48, 0xC5, 0x27, 0x72, 0xC0, 0xC5, 0xFA,  // .H.'r...
                        /* 0308 */  0x62, 0x23, 0xFE, 0x8C, 0xA5, 0xCC, 0xBD, 0x13,  // b#......
                        /* 0310 */  0x38, 0xAE, 0x75, 0x03, 0x03, 0xCB, 0xE2, 0x3B,  // 8.u....;
                        /* 0318 */  0xE5, 0x56, 0x9A, 0xB2, 0x5E, 0x36, 0xDE, 0xA9,  // .V..^6..
                        /* 0320 */  0x28, 0xB8, 0xD0, 0xAB, 0x4E, 0x23, 0x28, 0xA9,  // (...N#(.
                        /* 0328 */  0x90, 0x0D, 0xA6, 0x5B, 0xBE, 0xEF, 0x6E, 0xC9,  // ...[..n.
                        /* 0330 */  0x24, 0x09, 0xF4, 0xCB, 0xB3, 0x84, 0x28, 0xE5,  // $.....(.
                        /* 0338 */  0x82, 0x6E, 0xA7, 0x53, 0x0E, 0xB7, 0xB0, 0x8D,  // .n.S....
                        /* 0340 */  0x08, 0xFF, 0x14, 0x29, 0x2E, 0x80, 0x0C, 0xC9,  // ...)....
                        /* 0348 */  0xA9, 0x92, 0x52, 0xF1, 0xD6, 0x23, 0xFC, 0x4B,  // ..R..#.K
                        /* 0350 */  0xB3, 0xD7, 0x24, 0x0B, 0x71, 0x6D, 0xFB, 0x40,  // ..$.qm.@
                        /* 0358 */  0x0A, 0x68, 0x58, 0x81, 0xE4, 0x48, 0x22, 0x99,  // .hX..H".
                        /* 0360 */  0x4F, 0xB6, 0x71, 0x00, 0x18, 0x80, 0x61, 0x6F,  // O.q...ao
                        /* 0368 */  0x81, 0x9D, 0x35, 0xF2, 0x6F, 0x66, 0xCE, 0xE3,  // ..5.of..
                        /* 0370 */  0x0C, 0x81, 0x63, 0xE3, 0x52, 0x64, 0xAF, 0xEE,  // ..c.Rd..
                        /* 0378 */  0x48, 0x58, 0x2C, 0xFD, 0x44, 0x6E, 0xFA, 0x94,  // HX,.Dn..
                        /* 0380 */  0xE6, 0x7C, 0xF2, 0xC8, 0xE9, 0xB5, 0xF7, 0xB8,  // .|......
                        /* 0388 */  0x4D, 0xB1, 0x06, 0xA3, 0x68, 0x74, 0x82, 0x2C,  // M...ht.,
                        /* 0390 */  0xD2, 0xE2, 0xC3, 0xFC, 0x42, 0x76, 0x52, 0x21,  // ....BvR!
                        /* 0398 */  0x6D, 0x1A, 0x34, 0xEA, 0x3E, 0x80, 0xA8, 0x2A,  // m.4.>..*
                        /* 03A0 */  0x4D, 0xF6, 0x8A, 0x5C, 0xC6, 0xF4, 0x7C, 0xF7,  // M..\..|.
                        /* 03A8 */  0xBA, 0x6C, 0xB2, 0x6E, 0xC6, 0x52, 0x25, 0x69,  // .l.n.R%i
                        /* 03B0 */  0x84, 0xDA, 0x8B, 0x08, 0xBB, 0xBD, 0x46, 0x83,  // ......F.
                        /* 03B8 */  0x4F, 0x59, 0x5B, 0x79, 0xAB, 0x3F, 0x0E, 0xBD,  // OY[y.?..
                        /* 03C0 */  0x57, 0xA0, 0x03, 0xA5, 0x36, 0x06, 0xB9, 0xF1,  // W...6...
                        /* 03C8 */  0x8D, 0xDD, 0x76, 0x73, 0x67, 0xE9, 0x4C, 0x02,  // ..vsg.L.
                        /* 03D0 */  0x98, 0x54, 0xB3, 0x4C, 0x40, 0x72, 0x64, 0x79,  // .T.L@rdy
                        /* 03D8 */  0x5F, 0x9E, 0xB1, 0x30, 0x9F, 0xEF, 0xF6, 0xAE,  // _..0....
                        /* 03E0 */  0xBB, 0x31, 0x90, 0x4E, 0x6A, 0x19, 0x52, 0x2C,  // .1.Nj.R,
                        /* 03E8 */  0x4D, 0xB3, 0xC3, 0xED, 0xAD, 0x17, 0x6D, 0xE6,  // M.....m.
                        /* 03F0 */  0xE2, 0x7E, 0x55, 0xFE, 0x90, 0xCB, 0x60, 0x7A,  // .~U...`z
                        /* 03F8 */  0x63, 0x0A, 0x67, 0x0D, 0x8B, 0x3E, 0xCC, 0x9E,  // c.g..>..
                        /* 0400 */  0x38, 0xF7, 0x84, 0xF2, 0xC4, 0xA0, 0x71, 0x48,  // 8.....qH
                        /* 0408 */  0x6F, 0x43, 0x04, 0x89, 0x63, 0x6E, 0x82, 0x81,  // oC..cn..
                        /* 0410 */  0x5F, 0xC1, 0xBE, 0x51, 0x8E, 0x0A, 0xBE, 0x65,  // _..Q...e
                        /* 0418 */  0x7D, 0xBF, 0x2A, 0x47, 0xF7, 0x6F, 0x1C, 0x8A,  // }.*G.o..
                        /* 0420 */  0xA6, 0x4A, 0x04, 0x5D, 0xCA, 0x9F, 0x91, 0x04,  // .J.]....
                        /* 0428 */  0x3A, 0x35, 0x5B, 0x03, 0xC9, 0xD4, 0x8D, 0xBF,  // :5[.....
                        /* 0430 */  0xC7, 0x96, 0x6A, 0x24, 0x49, 0x3D, 0x01, 0xBA,  // ..j$I=..
                        /* 0438 */  0xF9, 0x41, 0xC0, 0x92, 0xF5, 0x75, 0xF6, 0x7D,  // .A...u.}
                        /* 0440 */  0x3B, 0xD2, 0xD7, 0x7B, 0xA2, 0xE3, 0x85, 0x85,  // ;..{....
                        /* 0448 */  0xEB, 0x89, 0x2B, 0xA8, 0x13, 0x04, 0xD8, 0xD9,  // ..+.....
                        /* 0450 */  0x7A, 0x07, 0x9A, 0x5E, 0x5E, 0x34, 0x1C, 0x3E,  // z..^^4.>
                        /* 0458 */  0x55, 0x81, 0x93, 0x84, 0x50, 0xB7, 0x9B, 0x6A,  // U...P..j
                        /* 0460 */  0x50, 0xF6, 0x2C, 0xB0, 0xCA, 0xC8, 0xEC, 0x28,  // P.,....(
                        /* 0468 */  0x4B, 0x76, 0xD6, 0x0C, 0xF0, 0xA8, 0xA7, 0x83,  // Kv......
                        /* 0470 */  0x24, 0xC5, 0x6D, 0xBC, 0x6E, 0x4E, 0xCB, 0x6C,  // $.m.nN.l
                        /* 0478 */  0xC5, 0xA0, 0x44, 0x63, 0x34, 0x01, 0x44, 0x68,  // ..Dc4.Dh
                        /* 0480 */  0x78, 0x99, 0xBB, 0x97, 0x8A, 0x35, 0xD0, 0xB5,  // x....5..
                        /* 0488 */  0x49, 0xDD, 0x21, 0xA1, 0xB9, 0x35, 0x97, 0x06,  // I.!..5..
                        /* 0490 */  0xF2, 0xBE, 0x71, 0x13, 0x50, 0x5C, 0xAF, 0xC9,  // ..q.P\..
                        /* 0498 */  0xFC, 0x98, 0x7A, 0x78, 0x8B, 0x5A, 0x49, 0x19,  // ..zx.ZI.
                        /* 04A0 */  0x10, 0x6D, 0xAF, 0xBD, 0x2C, 0xB1, 0xC7, 0xCC,  // .m..,...
                        /* 04A8 */  0x10, 0xDF, 0x90, 0x48, 0x95, 0xC1, 0x94, 0x6D,  // ...H...m
                        /* 04B0 */  0x83, 0x07, 0x61, 0x74, 0x61, 0x64, 0xCB, 0xCA,  // ..atad..
                        /* 04B8 */  0xB1, 0x9B, 0x82, 0x65, 0xA2, 0x8B, 0x3E, 0xAF,  // ...e..>.
                        /* 04C0 */  0x42, 0x3B, 0x1C, 0xBD, 0xC1, 0x94, 0x64, 0xEB,  // B;....d.
                        /* 04C8 */  0x5A, 0xCC, 0x22, 0x2B, 0xA1, 0xDA, 0x28, 0xC0,  // Z."+..(.
                        /* 04D0 */  0xA5, 0x2E, 0xD4, 0x91, 0x24, 0x3A, 0x05, 0x01,  // ....$:..
                        /* 04D8 */  0xEE, 0x1D, 0x52, 0xC4, 0xF8, 0x69, 0xAA, 0x87,  // ..R..i..
                        /* 04E0 */  0x1C, 0x78, 0x8C, 0xA3, 0x79, 0x57, 0xC1, 0x2C,  // .x..yW.,
                        /* 04E8 */  0x78, 0x60, 0x23, 0x02, 0x16, 0x31, 0x48, 0xB7,  // x`#..1H.
                        /* 04F0 */  0xBE, 0x8E, 0xDF, 0x8E, 0xB5, 0xD4, 0x72, 0x88,  // ......r.
                        /* 04F8 */  0x9A, 0xB6, 0x0D, 0x12, 0x28, 0x84, 0x7B, 0xD7,  // ....(.{.
                        /* 0500 */  0xCA, 0x29, 0x82, 0x81, 0x13, 0x7A, 0x21, 0x54,  // .)...z!T
                        /* 0508 */  0x5C, 0x29, 0xEC, 0x1C, 0xFC, 0xFC, 0xA6, 0x5A,  // \).....Z
                        /* 0510 */  0x79, 0xA1, 0x5D, 0xDA, 0x85, 0x30, 0x3E, 0xA1,  // y.]..0>.
                        /* 0518 */  0xFE, 0xF4, 0xC2, 0x44, 0x2F, 0xE8, 0x33, 0xA7,  // ...D/.3.
                        /* 0520 */  0xB0, 0x5B, 0xBB, 0xCA, 0xED, 0xD7, 0x38, 0xC5,  // .[....8.
                        /* 0528 */  0x07, 0x5E, 0x9F, 0xDD, 0xC1, 0x6E, 0xDE, 0x31,  // .^...n.1
                        /* 0530 */  0x5D, 0xED, 0x5C, 0xF0, 0x30, 0xA6, 0x12, 0xA3,  // ].\.0...
                        /* 0538 */  0x29, 0xA2, 0xCB, 0xE4, 0xA8, 0xCB, 0x6D, 0xC9,  // ).....m.
                        /* 0540 */  0x82, 0xC1, 0x5F, 0x5C, 0x47, 0x9D, 0x30, 0xC8,  // .._\G.0.
                        /* 0548 */  0x32, 0x99, 0x78, 0xE5, 0x27, 0x7F, 0x77, 0x36,  // 2.x.'.w6
                        /* 0550 */  0x1D, 0x27, 0x4F, 0x7D, 0xCE, 0x97, 0xE8, 0xDF,  // .'O}....
                        /* 0558 */  0xE9, 0x13, 0x87, 0x93, 0xA5, 0x69, 0xAD, 0xC9,  // .....i..
                        /* 0560 */  0xFA, 0x36, 0x8D, 0xA3, 0xC9, 0x1C, 0x8C, 0x99,  // .6......
                        /* 0568 */  0x67, 0x41, 0x74, 0x43, 0xEE, 0xDF, 0xEB, 0x09,  // gAtC....
                        /* 0570 */  0xFC, 0x91, 0xA2, 0x63, 0xA4, 0xBB, 0x2F, 0x9F,  // ...c../.
                        /* 0578 */  0x42, 0xFC, 0x75, 0x52, 0xC2, 0x8E, 0x68, 0x98,  // B.uR..h.
                        /* 0580 */  0xD6, 0xAE, 0x81, 0x6A, 0xD9, 0x1C, 0x2A, 0xE1,  // ...j..*.
                        /* 0588 */  0x37, 0x2F, 0xCC, 0xBE, 0x9E, 0x0B, 0xE5, 0xC8,  // 7/......
                        /* 0590 */  0x2A, 0x54, 0x76, 0xD8, 0xFF, 0xFA, 0x3E, 0x66,  // *Tv...>f
                        /* 0598 */  0x1D, 0x5D, 0x11, 0x19, 0x83, 0xF6, 0xE5, 0x99,  // .]......
                        /* 05A0 */  0xF6, 0x67, 0xE1, 0x71, 0xCF, 0xAE, 0x2F, 0xEE,  // .g.q../.
                        /* 05A8 */  0x62, 0xBA, 0x3A, 0xA9, 0x66, 0xA7, 0x29, 0xFD,  // b.:.f.).
                        /* 05B0 */  0x07, 0x00, 0x6F, 0xC2, 0xE3, 0x1F, 0xBD, 0x7B,  // ..o....{
                        /* 05B8 */  0x08, 0x58, 0xF7, 0xF8, 0x54, 0x61, 0x36, 0x8A,  // .X..Ta6.
                        /* 05C0 */  0xBC, 0x08, 0xDD, 0x32, 0xB3, 0xA3, 0xE3, 0x4F,  // ...2...O
                        /* 05C8 */  0x86, 0x35, 0x06, 0xF2, 0x76, 0x9C, 0x3C, 0xEF,  // .5..v.<.
                        /* 05D0 */  0x0D, 0x13, 0xF8, 0x32, 0x3D, 0xE0, 0x87, 0x5E,  // ...2=..^
                        /* 05D8 */  0x65, 0xBE, 0xDB, 0x2E, 0x06, 0xBE, 0x5F, 0xAB,  // e....._.
                        /* 05E0 */  0xC9, 0x15, 0xDB, 0xCB, 0x66, 0xF4, 0x3A, 0x0C,  // ....f.:.
                        /* 05E8 */  0xA7, 0xBB, 0x61, 0x74, 0x32, 0x1E, 0x77, 0xB3,  // ..at2.w.
                        /* 05F0 */  0xC0, 0xF8, 0x49, 0x4A, 0x6E, 0x00, 0xAA, 0xD2,  // ..IJn...
                        /* 05F8 */  0xA0, 0x25, 0x59, 0x57, 0xB6, 0xAA, 0xD1, 0x65,  // .%YW...e
                        /* 0600 */  0xFF, 0xF7, 0xBB, 0xF1, 0x59, 0xA9, 0x7A, 0x39,  // ....Y.z9
                        /* 0608 */  0xA3, 0xB0, 0x8A, 0x1B, 0xD6, 0x88, 0x9F, 0x64,  // .......d
                        /* 0610 */  0x41, 0xA3, 0xC2, 0x21, 0x9B, 0xD4, 0xA5, 0x60,  // A..!...`
                        /* 0618 */  0x4E, 0xB1, 0xCF, 0x7E, 0x2C, 0xDE, 0xC2, 0x19,  // N..~,...
                        /* 0620 */  0x0E, 0x12, 0x3E, 0xC3, 0x17, 0x96, 0x13, 0xD5,  // ..>.....
                        /* 0628 */  0x5D, 0x83, 0xFC, 0xD4, 0x4A, 0x49, 0x19, 0xB6,  // ]...JI..
                        /* 0630 */  0x69, 0x14, 0xF5, 0xE2, 0xC4, 0x6A, 0xD1, 0xAA,  // i....j..
                        /* 0638 */  0x3C, 0x8C, 0xD3, 0x85, 0x2B, 0xB9, 0x85, 0x4C,  // <...+..L
                        /* 0640 */  0x14, 0x5D, 0xDF, 0x93, 0x0B, 0xDF, 0xC6, 0xCE,  // .]......
                        /* 0648 */  0xD4, 0xA6, 0xB1, 0x46, 0x14, 0x4F, 0xEA, 0x83,  // ...F.O..
                        /* 0650 */  0x5C, 0xB0, 0x1F, 0xC1, 0x02, 0x27, 0xCC, 0x0D,  // \....'..
                        /* 0658 */  0x8B, 0xA9, 0x20, 0x88, 0xEB, 0xDC, 0x48, 0xEC,  // .. ...H.
                        /* 0660 */  0xD3, 0x58, 0x11, 0x78, 0x55, 0x4F, 0x85, 0x7F,  // .X.xUO..
                        /* 0668 */  0x6F, 0xA5, 0x86, 0x35, 0xBE, 0x94, 0xC3, 0xE5,  // o..5....
                        /* 0670 */  0xF3, 0x27, 0x7D, 0x1A, 0x3F, 0x57, 0xF3, 0x83,  // .'}.?W..
                        /* 0678 */  0x25, 0xE6, 0x04, 0x7F, 0x1F, 0x83, 0xFD, 0x66,  // %......f
                        /* 0680 */  0x14, 0xFB, 0xBC, 0xC2, 0x61, 0xFC, 0x1C, 0x40,  // ....a..@
                        /* 0688 */  0x66, 0xD6, 0x24, 0x76, 0x69, 0xF3, 0x2C, 0x59,  // f.$vi.,Y
                        /* 0690 */  0x29, 0x31, 0xA0, 0xED, 0x8A, 0xAB, 0x6F, 0xBC,  // )1....o.
                        /* 0698 */  0xCE, 0x0A, 0xFA, 0x48, 0xE8, 0x2F, 0x6E, 0x85,  // ...H./n.
                        /* 06A0 */  0x95, 0x56, 0xA5, 0x0A, 0xCB, 0x5F, 0x6F, 0x05,  // .V..._o.
                        /* 06A8 */  0x2F, 0x77, 0x31, 0x56, 0x88, 0x6F, 0xCF, 0x07,  // /w1V.o..
                        /* 06B0 */  0xBD, 0x5D, 0x69, 0xA6, 0xDE, 0x1E, 0xD0, 0x25,  // .]i....%
                        /* 06B8 */  0x4E, 0x57, 0xCE, 0x93, 0x61, 0x28, 0x0F, 0xC8,  // NW..a(..
                        /* 06C0 */  0x71, 0x37, 0xE8, 0x3D, 0x36, 0xC2, 0x94, 0x93,  // q7.=6...
                        /* 06C8 */  0x22, 0xE0, 0x8D, 0xE4, 0x99, 0x30, 0xB3, 0xED,  // "....0..
                        /* 06D0 */  0xCD, 0x1D, 0x80, 0xF8, 0xEF, 0xA2, 0x44, 0x44,  // ......DD
                        /* 06D8 */  0x0D, 0x87, 0x03, 0x9C, 0x9A, 0x1D, 0x36, 0x0B,  // ......6.
                        /* 06E0 */  0x45, 0x02, 0x0D, 0x85, 0x4F, 0x70, 0x97, 0xDA,  // E...Op..
                        /* 06E8 */  0x2E, 0x4C, 0xBC, 0xEC, 0xE0, 0xC1, 0xBB, 0xA5,  // .L......
                        /* 06F0 */  0x95, 0x2D, 0xD7, 0xC5, 0x88, 0x88, 0xA7, 0x20,  // .-..... 
                        /* 06F8 */  0x30, 0x70, 0x5B, 0xF5, 0x42, 0x1D, 0x41, 0xC3,  // 0p[.B.A.
                        /* 0700 */  0x6E, 0xE6, 0xE6, 0xDE, 0xA2, 0x6C, 0x4B, 0x63,  // n....lKc
                        /* 0708 */  0xD6, 0xCE, 0x5D, 0xC7, 0x51, 0x50, 0x91, 0xE7,  // ..].QP..
                        /* 0710 */  0x76, 0x9F, 0xED, 0xE1, 0x88, 0x7B, 0x3F, 0x9F,  // v....{?.
                        /* 0718 */  0x4B, 0x90, 0xC7, 0xA6, 0x39, 0x91, 0x44, 0x5E,  // K...9.D^
                        /* 0720 */  0x60, 0x4B, 0x49, 0x35, 0x3A, 0x91, 0x67, 0xEC,  // `KI5:.g.
                        /* 0728 */  0x7A, 0xC5, 0x18, 0x4B, 0x91, 0xC6, 0xF2, 0xFB,  // z..K....
                        /* 0730 */  0xA5, 0xDE, 0x9A, 0xA9, 0x1E, 0x34, 0x9E, 0x56,  // .....4.V
                        /* 0738 */  0x89, 0xCC, 0x98, 0x55, 0x2F, 0xEC, 0x88, 0x89,  // ...U/...
                        /* 0740 */  0x38, 0x4E, 0x1B, 0x60, 0x34, 0x2B, 0xA4, 0xDF,  // 8N.`4+..
                        /* 0748 */  0x1A, 0xDA, 0x90, 0x91, 0xD3, 0x13, 0x20, 0x67,  // ...... g
                        /* 0750 */  0x5D, 0xD0, 0x60, 0xE5, 0xE3, 0x33, 0x06, 0x33,  // ].`..3.3
                        /* 0758 */  0x2C, 0x61, 0x1E, 0xBD, 0x74, 0x15, 0x61, 0x1D,  // ,a..t.a.
                        /* 0760 */  0x81, 0x36, 0x78, 0x6B, 0x05, 0x8A, 0x97, 0x87,  // .6xk....
                        /* 0768 */  0x2B, 0xE1, 0xF6, 0x49, 0x7E, 0xE9, 0xDE, 0xBA,  // +..I~...
                        /* 0770 */  0xEE, 0x03, 0x92, 0x34, 0xAF, 0x16, 0xD2, 0xAB,  // ...4....
                        /* 0778 */  0xF7, 0xA4, 0x4A, 0xBA, 0x1E, 0x33, 0x3F, 0x75,  // ..J..3?u
                        /* 0780 */  0xA6, 0x5C, 0xCF, 0x0F, 0x53, 0x66, 0xD6, 0xAA,  // .\..Sf..
                        /* 0788 */  0xDE, 0x22, 0x2D, 0x84, 0x59, 0xCD, 0xB6, 0x72,  // ."-.Y..r
                        /* 0790 */  0x99, 0xEC, 0x29, 0xF5, 0x8A, 0xF6, 0xF7, 0xBD,  // ..).....
                        /* 0798 */  0x5F, 0xCE, 0x37, 0x3D, 0xA9, 0x51, 0xC3, 0x43,  // _.7=.Q.C
                        /* 07A0 */  0xB2, 0xF4, 0xD6, 0x63, 0x8B, 0x2E, 0x59, 0x95,  // ...c..Y.
                        /* 07A8 */  0x5D, 0x2A, 0x57, 0xED, 0xD6, 0x78, 0x58, 0x80,  // ]*W..xX.
                        /* 07B0 */  0x5F, 0x8F, 0xF5, 0xAC, 0xE1, 0xBE, 0x18, 0x1F,  // _.......
                        /* 07B8 */  0xA5, 0x3A, 0x68, 0x4E, 0x8B, 0x1D, 0x5D, 0x10,  // .:hN..].
                        /* 07C0 */  0xB7, 0x55, 0x46, 0x1B, 0x68, 0x6C, 0xC1, 0xBA,  // .UF.hl..
                        /* 07C8 */  0x3A, 0x71, 0xC9, 0xA6, 0x9D, 0xEA, 0xDE, 0x5D,  // :q.....]
                        /* 07D0 */  0x0F, 0x66, 0x2D, 0x72, 0x90, 0x0F, 0xB8, 0x87,  // .f-r....
                        /* 07D8 */  0x68, 0x18, 0x49, 0x3F, 0x8C, 0x2C, 0x11, 0x68,  // h.I?.,.h
                        /* 07E0 */  0x13, 0x75, 0x48, 0x08, 0x19, 0x75, 0x43, 0xE1,  // .uH..uC.
                        /* 07E8 */  0x14, 0x47, 0x68, 0x21, 0xD3, 0x4F, 0xE4, 0x71,  // .Gh!.O.q
                        /* 07F0 */  0x30, 0x43, 0x31, 0x86, 0x17, 0x52, 0x90, 0x96,  // 0C1..R..
                        /* 07F8 */  0xC1, 0x18, 0xC7, 0xB7, 0x81, 0xA8, 0x3E, 0xEE,  // ......>.
                        /* 0800 */  0xB9, 0xCC, 0xF5, 0x50, 0xE7, 0xBB, 0x36, 0x43,  // ...P..6C
                        /* 0808 */  0x94, 0xC2, 0x4A, 0x08, 0x78, 0x79, 0x52, 0x5A,  // ..J.xyRZ
                        /* 0810 */  0x4C, 0xDC, 0xF2, 0xE1, 0xA3, 0x3E, 0x65, 0x21,  // L....>e!
                        /* 0818 */  0x71, 0xA0, 0x95, 0xCD, 0xFB, 0xF3, 0x34, 0xB3,  // q.....4.
                        /* 0820 */  0x86, 0xF1, 0x19, 0x8A, 0x34, 0x2F, 0xF4, 0x6A,  // ....4/.j
                        /* 0828 */  0x26, 0xD7, 0x98, 0xB8, 0xAF, 0x58, 0x69, 0x55,  // &....XiU
                        /* 0830 */  0x60, 0x78, 0x88, 0x54, 0xD1, 0xC0, 0xF7, 0xF2,  // `x.T....
                        /* 0838 */  0x67, 0x3C, 0x4E, 0x80, 0x18, 0x5A, 0xB8, 0x6C,  // g<N..Z.l
                        /* 0840 */  0x0B, 0x18, 0xC1, 0x70, 0x2B, 0x49, 0x8D, 0x0C,  // ...p+I..
                        /* 0848 */  0xB7, 0xE1, 0xB6, 0xDB, 0xED, 0xDA, 0x67, 0x8D,  // ......g.
                        /* 0850 */  0xD0, 0xD2, 0x50, 0xB5, 0x55, 0xA9, 0x6C, 0xE1,  // ..P.U.l.
                        /* 0858 */  0x84, 0xD3, 0x76, 0xF2, 0x81, 0xFC, 0x2D, 0x5B,  // ..v...-[
                        /* 0860 */  0x57, 0xE6, 0x79, 0xAA, 0xAB, 0xB1, 0x40, 0xA4,  // W.y...@.
                        /* 0868 */  0x87, 0xE3, 0xF2, 0xF6, 0x75, 0x20, 0x06, 0x8C,  // ....u ..
                        /* 0870 */  0x9E, 0x80, 0x00, 0xE2, 0x27, 0x9D, 0xB5, 0x29,  // ....'..)
                        /* 0878 */  0x23, 0x0C, 0xDF, 0xDE, 0x6C, 0xE0, 0x9C, 0x49,  // #...l..I
                        /* 0880 */  0x23, 0x61, 0x8B, 0xA8, 0x36, 0xF0, 0xD8, 0x2A,  // #a..6..*
                        /* 0888 */  0x70, 0xD4, 0x8D, 0xB2, 0xA0, 0x07, 0x8D, 0x7A,  // p......z
                        /* 0890 */  0x7C, 0xB6, 0x0D, 0xDF, 0x4D, 0x31, 0xAB, 0xF8,  // |...M1..
                        /* 0898 */  0x43, 0x1B, 0xFF, 0x5E, 0xCE, 0x64, 0xF5, 0xA0,  // C..^.d..
                        /* 08A0 */  0x5C, 0x70, 0xB8, 0x34, 0x7C, 0x2B, 0x03, 0x91,  // \p.4|+..
                        /* 08A8 */  0xD9, 0x36, 0xFE, 0xFD, 0x5E, 0xE4, 0xAC, 0x3D,  // .6..^..=
                        /* 08B0 */  0x3C, 0x18, 0x73, 0x2A, 0xFD, 0x5F, 0xAE, 0x08,  // <.s*._..
                        /* 08B8 */  0xE2, 0x07, 0x3A, 0x56, 0x20, 0xD2, 0x8A, 0xD6,  // ..:V ...
                        /* 08C0 */  0x67, 0x50, 0x64, 0x15, 0x21, 0xAF, 0x4C, 0x29,  // gPd.!.L)
                        /* 08C8 */  0x34, 0x6E, 0x24, 0x0F, 0xFF, 0xAA, 0xBB, 0x3B,  // 4n$....;
                        /* 08D0 */  0x19, 0x3F, 0xBB, 0x6A, 0x32, 0x13, 0xEC, 0x8B,  // .?.j2...
                        /* 08D8 */  0x3D, 0x89, 0x3D, 0x23, 0x4B, 0x4A, 0x6D, 0x96,  // =.=#KJm.
                        /* 08E0 */  0x42, 0xD9, 0xFB, 0x27, 0x39, 0xA8, 0x74, 0xEF,  // B..'9.t.
                        /* 08E8 */  0x8D, 0x74, 0x6A, 0xAF, 0x32, 0x9B, 0xB9, 0x0C,  // .tj.2...
                        /* 08F0 */  0x53, 0x5F, 0x9A, 0x46, 0xF7, 0x74, 0xC0, 0x18,  // S_.F.t..
                        /* 08F8 */  0x1C, 0x33, 0x87, 0x8A, 0xFF, 0xE1, 0x62, 0x9B,  // .3....b.
                        /* 0900 */  0x64, 0x67, 0xEE, 0x67, 0x53, 0xF1, 0x48, 0x04,  // dg.gS.H.
                        /* 0908 */  0x5E, 0x69, 0x94, 0x7F, 0x48, 0xD3, 0xB4, 0xE1,  // ^i..H...
                        /* 0910 */  0xC9, 0x4B, 0xD8, 0x3F, 0x5F, 0x67, 0x1F, 0x93,  // .K.?_g..
                        /* 0918 */  0x4E, 0x66, 0xFA, 0x40, 0x7F, 0x6B, 0xB3, 0xBE,  // Nf.@.k..
                        /* 0920 */  0x57, 0x27, 0x15, 0xB9, 0x39, 0x4D, 0x1F, 0x2B,  // W'..9M.+
                        /* 0928 */  0xCE, 0xA5, 0x61, 0x35, 0x8A, 0x67, 0x32, 0x9E,  // ..a5.g2.
                        /* 0930 */  0x89, 0xE2, 0xBB, 0x03, 0x1E, 0xD1, 0x03, 0x71,  // .......q
                        /* 0938 */  0xB1, 0xEE, 0x57, 0x79, 0x8A, 0x3D, 0x83, 0xBE,  // ..Wy.=..
                        /* 0940 */  0x3C, 0x9F, 0x8B, 0x3F, 0xD9, 0xC3, 0x9E, 0x7C,  // <..?...|
                        /* 0948 */  0xB4, 0x3F, 0xEB, 0x45, 0xAC, 0x5F, 0x01, 0xA8,  // .?.E._..
                        /* 0950 */  0xF2, 0x7D, 0xC1, 0x62, 0x16, 0x6E, 0x36, 0xFA,  // .}.b.n6.
                        /* 0958 */  0x3C, 0xAB, 0xFA, 0xAC, 0x29, 0xDE, 0x09, 0x21,  // <...)..!
                        /* 0960 */  0xC1, 0xEB, 0x5E, 0xAE, 0x0B, 0x3D, 0xA1, 0xAF,  // ..^..=..
                        /* 0968 */  0x70, 0x15, 0x87, 0xF5, 0x48, 0x62, 0x12, 0x85,  // p...Hb..
                        /* 0970 */  0x43, 0xC3, 0xD7, 0x36, 0x87, 0x30, 0x8B, 0xD6,  // C..6.0..
                        /* 0978 */  0x37, 0x04, 0x5C, 0x10, 0x1C, 0xAA, 0x3A, 0x6A,  // 7.\...:j
                        /* 0980 */  0x96, 0x55, 0x53, 0x35, 0x66, 0x98, 0x6C, 0x2C,  // .US5f.l,
                        /* 0988 */  0x21, 0x37, 0xB4, 0xB5, 0x40, 0x2B, 0x47, 0x38,  // !7..@+G8
                        /* 0990 */  0x86, 0xA1, 0x21, 0x5D, 0x89, 0xB5, 0xA7, 0x3F,  // ..!]...?
                        /* 0998 */  0xC5, 0xEF, 0x75, 0x10, 0x72, 0xE4, 0x9C, 0x85,  // ..u.r...
                        /* 09A0 */  0x82, 0x6A, 0x66, 0x5C, 0x79, 0x5C, 0x82, 0x82,  // .jf\y\..
                        /* 09A8 */  0x0F, 0xF5, 0x0C, 0xE0, 0xF4, 0x90, 0xC3, 0xB7,  // ........
                        /* 09B0 */  0xFC, 0x42, 0xCE, 0xBA, 0x06, 0xB9, 0xA6, 0x75,  // .B.....u
                        /* 09B8 */  0x75, 0xF7, 0x85, 0x7E, 0xD7, 0x1D, 0x3D, 0xDD,  // u..~..=.
                        /* 09C0 */  0xBE, 0x62, 0x5F, 0xC1, 0x07, 0x58, 0xE7, 0x9B,  // .b_..X..
                        /* 09C8 */  0x9B, 0xED, 0x32, 0xEC, 0xCC, 0xA8, 0xAD, 0x8D,  // ..2.....
                        /* 09D0 */  0x78, 0x8F, 0xC3, 0x0F, 0x41, 0x0E, 0x4D, 0xC6,  // x...A.M.
                        /* 09D8 */  0xC3, 0x2D, 0x99, 0x72, 0xC7, 0x3B, 0xF1, 0x3C,  // .-.r.;.<
                        /* 09E0 */  0x84, 0xDC, 0x74, 0xB6, 0xCC, 0x6F, 0xF2, 0xC2,  // ..t..o..
                        /* 09E8 */  0x22, 0x3A, 0x8F, 0x52, 0x8D, 0xC1, 0xCC, 0x8B,  // ":.R....
                        /* 09F0 */  0x8C, 0x4E, 0x86, 0x96, 0xFB, 0xC6, 0x3D, 0x83,  // .N....=.
                        /* 09F8 */  0x39, 0x0F, 0xA2, 0xC6, 0x5B, 0x4E, 0x61, 0xBB,  // 9...[Na.
                        /* 0A00 */  0x6C, 0x4F, 0x65, 0x47, 0xFB, 0xB6, 0xD3, 0xD3,  // lOeG....
                        /* 0A08 */  0x0F, 0x02, 0x84, 0x03, 0x05, 0x90, 0x13, 0xD3,  // ........
                        /* 0A10 */  0xDE, 0x12, 0x96, 0xC9, 0x6D, 0x21, 0x2F, 0x4C,  // ....m!/L
                        /* 0A18 */  0x72, 0x41, 0x26, 0x15, 0x90, 0x7F, 0xC8, 0xEC,  // rA&.....
                        /* 0A20 */  0xCA, 0x3D, 0x19, 0xCD, 0xA7, 0xBD, 0xCE, 0xE4,  // .=......
                        /* 0A28 */  0x5F, 0x16, 0x76, 0xAF, 0xA5, 0x33, 0xCE, 0x84,  // _.v..3..
                        /* 0A30 */  0x76, 0x76, 0x22, 0x2A, 0x92, 0x19, 0x56, 0xDE,  // vv"*..V.
                        /* 0A38 */  0xB7, 0xDF, 0xAB, 0xF1, 0x76, 0xF5, 0xA5, 0x6D,  // ....v..m
                        /* 0A40 */  0x62, 0x6E, 0x8D, 0xA2, 0x00, 0xCE, 0x41, 0x0A,  // bn....A.
                        /* 0A48 */  0xA0, 0xDF, 0x53, 0x74, 0x1D, 0xBC, 0xE9, 0xAE,  // ..St....
                        /* 0A50 */  0x6E, 0xD3, 0x8E, 0x85, 0x01, 0xCC, 0x66, 0xC6,  // n.....f.
                        /* 0A58 */  0x1F, 0x1F, 0x87, 0x2B, 0xC4, 0x95, 0xA1, 0x07,  // ...+....
                        /* 0A60 */  0xE9, 0x88, 0xFD, 0x63, 0xC8, 0xBA, 0xC7, 0x0D,  // ...c....
                        /* 0A68 */  0x5B, 0x0B, 0xB1, 0xEC, 0x10, 0x80, 0x06, 0xEE,  // [.......
                        /* 0A70 */  0x12, 0xDB, 0x28, 0x94, 0xC4, 0xFA, 0x17, 0x80,  // ..(.....
                        /* 0A78 */  0x82, 0x8B, 0x97, 0x47, 0xBD, 0xD3, 0x9B, 0xE9,  // ...G....
                        /* 0A80 */  0x8F, 0x8B, 0xC5, 0x31, 0xF1, 0x74, 0x76, 0x77,  // ...1.tvw
                        /* 0A88 */  0x15, 0xE4, 0x63, 0x92, 0x3B, 0x13, 0x92, 0x43,  // ..c.;..C
                        /* 0A90 */  0x9A, 0x08, 0xA7, 0x24, 0x0D, 0xEA, 0x23, 0x3C,  // ...$..#<
                        /* 0A98 */  0xF0, 0x00, 0x04, 0xC8, 0x11, 0x75, 0x26, 0x22,  // .....u&"
                        /* 0AA0 */  0xA7, 0x32, 0x74, 0xDA, 0x99, 0x9E, 0x6D, 0x25,  // .2t...m%
                        /* 0AA8 */  0x18, 0x54, 0xAA, 0x3C, 0x73, 0x46, 0x47, 0x58,  // .T.<sFGX
                        /* 0AB0 */  0xF8, 0x13, 0x32, 0xD9, 0xCB, 0x71, 0xC2, 0xF2,  // ..2..q..
                        /* 0AB8 */  0x73, 0xDD, 0x41, 0x1B, 0x57, 0x19, 0x8D, 0x8D,  // s.A.W...
                        /* 0AC0 */  0x7B, 0x5C, 0x7C, 0xF7, 0x6A, 0x5C, 0x8A, 0x64,  // {\|.j\.d
                        /* 0AC8 */  0x74, 0xD9, 0xD9, 0x99, 0xA4, 0xCD, 0xFC, 0xE2,  // t.......
                        /* 0AD0 */  0x38, 0x9F, 0xA5, 0x92, 0xAE, 0xC6, 0x7A, 0x10,  // 8.....z.
                        /* 0AD8 */  0x05, 0xC9, 0x4D, 0x8B, 0xBB, 0x7B, 0xE2, 0x1C,  // ..M..{..
                        /* 0AE0 */  0x9B, 0x9C, 0x87, 0x1F, 0x10, 0x7E, 0xB1, 0x7A,  // .....~.z
                        /* 0AE8 */  0xB9, 0xBB, 0xC0, 0x6F, 0x51, 0x2C, 0xD1, 0x08,  // ...oQ,..
                        /* 0AF0 */  0xB6, 0x40, 0x01, 0x7C, 0x5F, 0xDB, 0xCB, 0x6E,  // .@.|_..n
                        /* 0AF8 */  0xF8, 0x68, 0x53, 0xA5, 0x1F, 0x87, 0xC8, 0x42,  // .hS....B
                        /* 0B00 */  0x16, 0xF9, 0x0C, 0x24, 0x36, 0x37, 0x6E, 0x44,  // ...$67nD
                        /* 0B08 */  0xD7, 0x7B, 0x04, 0x9C, 0x18, 0xCE, 0x88, 0x34,  // .{.....4
                        /* 0B10 */  0xBD, 0x7B, 0x3D, 0xEC, 0x46, 0xFF, 0xC2, 0xCC,  // .{=.F...
                        /* 0B18 */  0x30, 0x4F, 0x0F, 0xCC, 0x8A, 0xD3, 0x8F, 0x7B,  // 0O.....{
                        /* 0B20 */  0x0D, 0xE4, 0x70, 0x19, 0x6C, 0x36, 0x98, 0x79,  // ..p.l6.y
                        /* 0B28 */  0xF7, 0xBD, 0xCA, 0x4A, 0x82, 0x96, 0x62, 0xC4,  // ...J..b.
                        /* 0B30 */  0x28, 0xB3, 0x87, 0x68, 0xDE, 0xAD, 0x0C, 0xE1,  // (..h....
                        /* 0B38 */  0xAB, 0xDB, 0x2F, 0x7E, 0xA5, 0xB3, 0x23, 0x9A,  // ../~..#.
                        /* 0B40 */  0x76, 0x0B, 0x21, 0x78, 0xA3, 0x93, 0x04, 0x90,  // v.!x....
                        /* 0B48 */  0x7D, 0x94, 0xB2, 0x9D, 0x16, 0x5E, 0xD9, 0x5B,  // }....^.[
                        /* 0B50 */  0xE5, 0x35, 0x0C, 0x81, 0x79, 0x66, 0x42, 0x7F,  // .5..yfB.
                        /* 0B58 */  0xAA, 0x1B, 0x8A, 0xF6, 0x3F, 0x0B, 0x65, 0x75,  // ....?.eu
                        /* 0B60 */  0x5B, 0x55, 0x58, 0x50, 0x75, 0xE7, 0x54, 0x8B,  // [UXPu.T.
                        /* 0B68 */  0x7D, 0x81, 0x09, 0x20, 0xA3, 0x7D, 0x89, 0x9A,  // }.. .}..
                        /* 0B70 */  0x59, 0x22, 0x0E, 0xE2, 0xC4, 0xCB, 0x75, 0x59,  // Y"....uY
                        /* 0B78 */  0x17, 0x64, 0x80, 0x8F, 0x8D, 0xBE, 0x4E, 0xAF,  // .d....N.
                        /* 0B80 */  0x7A, 0x5F, 0x4D, 0x4A, 0x1B, 0x6C, 0x64, 0x3A,  // z_MJ.ld:
                        /* 0B88 */  0xA5, 0xD9, 0xAF, 0xC6, 0x4F, 0x2A, 0x86, 0xB7,  // ....O*..
                        /* 0B90 */  0x72, 0xD9, 0x9E, 0x59, 0x2A, 0x8C, 0x12, 0x8B,  // r..Y*...
                        /* 0B98 */  0xF8, 0x4D, 0xC0, 0x5A, 0x96, 0x9F, 0xE7, 0x4B,  // .M.Z...K
                        /* 0BA0 */  0x3C, 0xB8, 0xD8, 0x68, 0xD6, 0xAA, 0xD6, 0xA5,  // <..h....
                        /* 0BA8 */  0x0C, 0xCB, 0xF3, 0x04, 0x4C, 0x6D, 0x9D, 0x78,  // ....Lm.x
                        /* 0BB0 */  0xBE, 0x26, 0x9D, 0x8D, 0xAE, 0x8E, 0x4C, 0xC3,  // .&....L.
                        /* 0BB8 */  0x35, 0xF4, 0xCB, 0xB4, 0xC9, 0xB1, 0x20, 0x8B,  // 5..... .
                        /* 0BC0 */  0x1A, 0x30, 0xA3, 0xB5, 0x1E, 0x58, 0xDB, 0x18,  // .0...X..
                        /* 0BC8 */  0x13, 0x8E, 0x48, 0x05, 0xEE, 0x44, 0xC7, 0x7D,  // ..H..D.}
                        /* 0BD0 */  0xEA, 0xC5, 0x89, 0xD1, 0x71, 0xDB, 0xAA, 0xEE,  // ....q...
                        /* 0BD8 */  0xC1, 0xA9, 0x34, 0xC1, 0x52, 0x64, 0x2E, 0xAD,  // ..4.Rd..
                        /* 0BE0 */  0x59, 0x23, 0x8B, 0x7D, 0x96, 0x05, 0x9E, 0xA7,  // Y#.}....
                        /* 0BE8 */  0xE6, 0x0D, 0x6E, 0x20, 0xDB, 0xBA, 0x32, 0x73,  // ..n ..2s
                        /* 0BF0 */  0xB9, 0x5D, 0x4B, 0xB5, 0x25, 0x4B, 0xBB, 0xDE,  // .]K.%K..
                        /* 0BF8 */  0x98, 0x20, 0xBE, 0x7E, 0x75, 0xCD, 0xB1, 0x02,  // . .~u...
                        /* 0C00 */  0xC9, 0xBB, 0x63, 0x9E, 0xB6, 0xE1, 0xBA, 0x23,  // ..c....#
                        /* 0C08 */  0x14, 0x74, 0xDD, 0x0C, 0x54, 0x28, 0x35, 0xAC,  // .t..T(5.
                        /* 0C10 */  0x83, 0x20, 0x92, 0x13, 0x82, 0x2B, 0xF9, 0x56,  // . ...+.V
                        /* 0C18 */  0x25, 0x3C, 0xE7, 0x09, 0x66, 0x3B, 0xEA, 0x0F,  // %<..f;..
                        /* 0C20 */  0xAE, 0xF6, 0x57, 0xBC, 0xEB, 0x9D, 0xDD, 0xBE,  // ..W.....
                        /* 0C28 */  0x19, 0x36, 0xDD, 0x90, 0x26, 0xC9, 0x1E, 0xE3,  // .6..&...
                        /* 0C30 */  0x24, 0xC8, 0x5B, 0x50, 0xBA, 0x64, 0x4D, 0x28,  // $.[P.dM(
                        /* 0C38 */  0xE7, 0x4F, 0xF1, 0x91, 0x45, 0x2E, 0x02, 0x2D,  // .O..E..-
                        /* 0C40 */  0xB1, 0xF7, 0x90, 0x61, 0xA1, 0x55, 0x9A, 0xFB,  // ...a.U..
                        /* 0C48 */  0xC4, 0x80, 0x62, 0xFC, 0xB9, 0x84, 0xF3, 0x91,  // ..b.....
                        /* 0C50 */  0xF8, 0x18, 0x72, 0xDA, 0xB3, 0x1B, 0xC6, 0x48,  // ..r....H
                        /* 0C58 */  0x52, 0x93, 0x5A, 0xBA, 0x5B, 0x15, 0x4E, 0x4B,  // R.Z.[.NK
                        /* 0C60 */  0x2D, 0xAB, 0x12, 0x55, 0xED, 0x86, 0xAE, 0x8A,  // -..U....
                        /* 0C68 */  0x85, 0x4B, 0x20, 0x08, 0xFF, 0x30, 0x53, 0x26,  // .K ..0S&
                        /* 0C70 */  0xFB, 0x07, 0xFF, 0x7B, 0xC4, 0x2D, 0x84, 0xF5,  // ...{.-..
                        /* 0C78 */  0x9D, 0x3B, 0x99, 0x28, 0xE7, 0x92, 0xEC, 0xE2,  // .;.(....
                        /* 0C80 */  0x49, 0x4C, 0x60, 0xDD, 0x5E, 0x07, 0x32, 0x0B,  // IL`.^.2.
                        /* 0C88 */  0x5B, 0xA8, 0x63, 0xA5, 0x9D, 0x68, 0x19, 0xFD,  // [.c..h..
                        /* 0C90 */  0x5E, 0x5B, 0x51, 0xAC, 0xF5, 0x18, 0x0B, 0x6D,  // ^[Q....m
                        /* 0C98 */  0x26, 0x6E, 0xDD, 0xED, 0xC6, 0x53, 0x87, 0x20,  // &n...S. 
                        /* 0CA0 */  0x47, 0x6A, 0x3E, 0x03, 0xEC, 0x8A, 0x23, 0xE0,  // Gj>...#.
                        /* 0CA8 */  0x51, 0xB5, 0xFD, 0xF2, 0x90, 0x4E, 0xB1, 0x37,  // Q....N.7
                        /* 0CB0 */  0xE3, 0xED, 0xAD, 0xF0, 0x12, 0x89, 0x97, 0x69,  // .......i
                        /* 0CB8 */  0x1D, 0x8A, 0x65, 0x30, 0x10, 0x64, 0x78, 0x9B,  // ..e0.dx.
                        /* 0CC0 */  0x93, 0xA5, 0x34, 0xD2, 0x6E, 0x63, 0xC6, 0x05,  // ..4.nc..
                        /* 0CC8 */  0x57, 0x7D, 0x81, 0x3F, 0x9E, 0x65, 0x1D, 0xA4,  // W}.?.e..
                        /* 0CD0 */  0x64, 0x1B, 0x07, 0xDA, 0x34, 0x20, 0x6F, 0x8C,  // d...4 o.
                        /* 0CD8 */  0xEB, 0xF1, 0x2D, 0x62, 0x48, 0xEB, 0xCD, 0x4A,  // ..-bH..J
                        /* 0CE0 */  0xC5, 0x2D, 0x4D, 0xEC, 0xB4, 0xB7, 0x85, 0x6D,  // .-M....m
                        /* 0CE8 */  0x96, 0x3E, 0x0F, 0xE8, 0xC6, 0xB2, 0x72, 0x2E,  // .>....r.
                        /* 0CF0 */  0x59, 0x3A, 0x6D, 0xD8, 0x1B, 0xDD, 0xDA, 0xF0,  // Y:m.....
                        /* 0CF8 */  0x01, 0xB9, 0x44, 0x78, 0x5A, 0x42, 0xFC, 0x45,  // ..DxZB.E
                        /* 0D00 */  0x6E, 0x3E, 0x05, 0x9A, 0xA9, 0xE2, 0xA5, 0xD9,  // n>......
                        /* 0D08 */  0x8C, 0x70, 0x37, 0xE3, 0x47, 0xC6, 0x4C, 0x1A,  // .p7.G.L.
                        /* 0D10 */  0xC1, 0x95, 0x0A, 0x81, 0x44, 0x31, 0x6D, 0xAD,  // ....D1m.
                        /* 0D18 */  0xC9, 0xD0, 0xA3, 0x7C, 0x42, 0x9D, 0x76, 0x3E,  // ...|B.v>
                        /* 0D20 */  0xE8, 0x23, 0x81, 0x73, 0x9B, 0x3F, 0x17, 0xB7,  // .#.s.?..
                        /* 0D28 */  0xE5, 0x02, 0xCA, 0x86, 0xE8, 0xF1, 0xA3, 0x20,  // ....... 
                        /* 0D30 */  0xBC, 0x44, 0x19, 0xDA, 0x05, 0xD1, 0x12, 0xC6,  // .D......
                        /* 0D38 */  0xEF, 0xA6, 0xE7, 0xB0, 0xF1, 0x5D, 0xE2, 0xDF,  // .....]..
                        /* 0D40 */  0x5A, 0x39, 0xB1, 0xBD, 0xAD, 0xB9, 0xA9, 0xB4,  // Z9......
                        /* 0D48 */  0xB7, 0xE3, 0x37, 0xB0, 0xBF, 0xA6, 0x21, 0x60,  // ..7...!`
                        /* 0D50 */  0xBC, 0x47, 0x9E, 0x68, 0xDF, 0x23, 0xB7, 0x7B,  // .G.h.#.{
                        /* 0D58 */  0x3A, 0x40, 0x9A, 0x5F, 0x86, 0xFB, 0x1C, 0x9F,  // :@._....
                        /* 0D60 */  0x2E, 0x1E, 0x02, 0xC2, 0x73, 0x56, 0x79, 0xA0,  // ....sVy.
                        /* 0D68 */  0xB5, 0x60, 0x19, 0x02, 0x40, 0x79, 0x07, 0x57,  // .`..@y.W
                        /* 0D70 */  0xD7, 0x73, 0xDA, 0x70, 0x5B, 0xF2, 0xA9, 0x6B,  // .s.p[..k
                        /* 0D78 */  0x36, 0x61, 0x7C, 0xE5, 0xE9, 0x44, 0xCD, 0xC1,  // 6a|..D..
                        /* 0D80 */  0xEE, 0x4B, 0x8D, 0x65, 0x45, 0x16, 0x12, 0xAE,  // .K.eE...
                        /* 0D88 */  0xBF, 0x33, 0x40, 0xF8, 0x40, 0xC7, 0xE1, 0x06,  // .3@.@...
                        /* 0D90 */  0x10, 0x94, 0x78, 0x01, 0xDC, 0xCB, 0x6B, 0xD9,  // ..x...k.
                        /* 0D98 */  0x5A, 0xF1, 0x54, 0x8D, 0x5E, 0xC6, 0x5C, 0xB6,  // Z.T.^.\.
                        /* 0DA0 */  0xB3, 0x7C, 0xC9, 0xF7, 0x8A, 0x35, 0xD5, 0x00,  // .|...5..
                        /* 0DA8 */  0x62, 0x0C, 0xC2, 0xED, 0x03, 0xBC, 0x41, 0x03,  // b.....A.
                        /* 0DB0 */  0x3E, 0xC7, 0x54, 0x54, 0x0F, 0x2E, 0xAF, 0x4A,  // >.TT...J
                        /* 0DB8 */  0x33, 0x72, 0x01, 0x4E, 0x7A, 0x63, 0xE3, 0xFE,  // 3r.Nzc..
                        /* 0DC0 */  0xD1, 0xEC, 0xD7, 0x28, 0x33, 0x29, 0xD0, 0x60,  // ...(3).`
                        /* 0DC8 */  0x54, 0x92, 0xDB, 0x9B, 0xEC, 0xA5, 0xDE, 0x8B,  // T.......
                        /* 0DD0 */  0x2A, 0xE2, 0x2A, 0xF4, 0x29, 0xD2, 0x33, 0x49,  // *.*.).3I
                        /* 0DD8 */  0xDD, 0x23, 0x8A, 0x76, 0x76, 0x9C, 0x6B, 0x32,  // .#.vv.k2
                        /* 0DE0 */  0x89, 0x7F, 0xA0, 0x86, 0x6C, 0x83, 0x2C, 0xBE,  // ....l.,.
                        /* 0DE8 */  0x9C, 0xED, 0x78, 0xF5, 0xDD, 0x08, 0x58, 0xA4,  // ..x...X.
                        /* 0DF0 */  0x9B, 0xFC, 0x1C, 0x8F, 0x23, 0x7C, 0x85, 0xDA,  // ....#|..
                        /* 0DF8 */  0xFB, 0x2E, 0x71, 0xF6, 0x5F, 0x45, 0xD7, 0x8E,  // ..q._E..
                        /* 0E00 */  0xEF, 0xC5, 0xBA, 0x10, 0x3B, 0x3D, 0xB2, 0x3C,  // ....;=.<
                        /* 0E08 */  0xF9, 0x90, 0xF2, 0x38, 0x84, 0x2A, 0xD0, 0x3B,  // ...8.*.;
                        /* 0E10 */  0x2C, 0x09, 0x37, 0x1D, 0x28, 0x59, 0xC4, 0x3C,  // ,.7.(Y.<
                        /* 0E18 */  0x47, 0x61, 0x30, 0x1A, 0xF3, 0x69, 0x03, 0xE2,  // Ga0..i..
                        /* 0E20 */  0x25, 0x8E, 0x0C, 0x71, 0x75, 0x37, 0xCF, 0x60,  // %..qu7.`
                        /* 0E28 */  0x34, 0x17, 0x9A, 0xC3, 0x3A, 0xD2, 0xF7, 0x72,  // 4...:..r
                        /* 0E30 */  0xAC, 0x66, 0xA9, 0x61, 0xAA, 0x37, 0x05, 0x6C,  // .f.a.7.l
                        /* 0E38 */  0x2F, 0xD7, 0x4A, 0x7B, 0x43, 0x46, 0xFA, 0x6B,  // /.J{CF.k
                        /* 0E40 */  0x64, 0xB7, 0xDC, 0xBF, 0xB6, 0xB5, 0x43, 0x1F,  // d.....C.
                        /* 0E48 */  0x29, 0xDB, 0x8D, 0x16, 0xBB, 0xC7, 0xB1, 0x61,  // )......a
                        /* 0E50 */  0x7D, 0xDB, 0x1B, 0xF1, 0x13, 0xBE, 0x26, 0xE4,  // }.....&.
                        /* 0E58 */  0xBD, 0xE3, 0xCD, 0xEB, 0x15, 0xFC, 0x5F, 0xD3,  // ......_.
                        /* 0E60 */  0x43, 0x44, 0x09, 0xA2, 0x34, 0x48, 0x1A, 0xAE,  // CD..4H..
                        /* 0E68 */  0xD4, 0xA9, 0x38, 0x41, 0xB0, 0xCF, 0xCA, 0x4A,  // ..8A...J
                        /* 0E70 */  0x60, 0xB7, 0x14, 0xA3, 0xA6, 0xFD, 0xC7, 0xAD,  // `.......
                        /* 0E78 */  0xEE, 0xFA, 0xDB, 0x93, 0xC2, 0x17, 0x13, 0xAE,  // ........
                        /* 0E80 */  0x04, 0xEA, 0xC4, 0xD5, 0x9C, 0xF7, 0x15, 0xE2,  // ........
                        /* 0E88 */  0xF7, 0x7D, 0x88, 0xF3, 0xB1, 0x15, 0xB4, 0xE6,  // .}......
                        /* 0E90 */  0x6E, 0xBC, 0x63, 0xB6, 0x79, 0x3E, 0xC6, 0x38,  // n.c.y>.8
                        /* 0E98 */  0x22, 0x36, 0x35, 0x3F, 0xA7, 0x40, 0x1F, 0x84,  // "65?.@..
                        /* 0EA0 */  0xB9, 0x3D, 0x1B, 0x42, 0xDA, 0xC1, 0xD3, 0x47,  // .=.B...G
                        /* 0EA8 */  0xAA, 0x26, 0xDA, 0xC3, 0xA7, 0xED, 0x2A, 0x70,  // .&....*p
                        /* 0EB0 */  0xE1, 0xD6, 0xC5, 0x18, 0x5B, 0x5A, 0x66, 0x50,  // ....[ZfP
                        /* 0EB8 */  0xFE, 0x9F, 0x25, 0xC8, 0x73, 0xBA, 0x2E, 0xE7,  // ..%.s...
                        /* 0EC0 */  0x90, 0xD6, 0xFF, 0x04, 0x21, 0xC8, 0x1F, 0x85,  // ....!...
                        /* 0EC8 */  0x87, 0x93, 0x3C, 0x01, 0x6D, 0x71, 0x60, 0xD4,  // ..<.mq`.
                        /* 0ED0 */  0xC6, 0xCC, 0x44, 0x26, 0x58, 0x7B, 0x29, 0xB1,  // ..D&X{).
                        /* 0ED8 */  0x32, 0x79, 0x08, 0xAC, 0x17, 0x73, 0x9D, 0x58,  // 2y...s.X
                        /* 0EE0 */  0x2D, 0xF8, 0xC6, 0x10, 0xA1, 0x12, 0xCB, 0xB8,  // -.......
                        /* 0EE8 */  0xA6, 0xA5, 0x74, 0x67, 0x2C, 0x06, 0x13, 0xB7,  // ..tg,...
                        /* 0EF0 */  0xEF, 0x81, 0x5B, 0x57, 0xD7, 0x8A, 0xB7, 0xD8,  // ..[W....
                        /* 0EF8 */  0x76, 0xFF, 0xD8, 0x2A, 0x16, 0xAF, 0xFB, 0xCA,  // v..*....
                        /* 0F00 */  0x0A, 0xE1, 0xFA, 0x4B, 0x9A, 0x69, 0x4D, 0x2D,  // ...K.iM-
                        /* 0F08 */  0x44, 0xD6, 0x9E, 0x75, 0x9A, 0x7A, 0xB8, 0x40,  // D..u.z.@
                        /* 0F10 */  0x41, 0x78, 0x98, 0x85, 0xD4, 0x8B, 0xE7, 0xAC,  // Ax......
                        /* 0F18 */  0x07, 0x64, 0x4E, 0x9C, 0x8A, 0xAE, 0x6D, 0x56,  // .dN...mV
                        /* 0F20 */  0x3A, 0x60, 0xDD, 0x6E, 0x91, 0xE2, 0xE4, 0xD0,  // :`.n....
                        /* 0F28 */  0x68, 0x87, 0xD7, 0xDF, 0xB5, 0x58, 0x37, 0x2D,  // h....X7-
                        /* 0F30 */  0x97, 0x0D, 0xC2, 0xF1, 0x39, 0xEF, 0x1F, 0xB2,  // ....9...
                        /* 0F38 */  0xFE, 0xBA, 0x93, 0xAA, 0x44, 0x3E, 0x10, 0x2C,  // ....D>.,
                        /* 0F40 */  0x1A, 0x9C, 0x97, 0xCD, 0xBF, 0x49, 0xDB, 0x5F,  // .....I._
                        /* 0F48 */  0xF3, 0x4C, 0x35, 0x0C, 0x52, 0xE8, 0xA6, 0x5F,  // .L5.R.._
                        /* 0F50 */  0xA5, 0x91, 0xB7, 0x7C, 0x80, 0xE0, 0xE8, 0xAD,  // ...|....
                        /* 0F58 */  0x24, 0xD2, 0x73, 0xCB, 0xB3, 0x2A, 0xE8, 0x21,  // $.s..*.!
                        /* 0F60 */  0x5B, 0xBD, 0xD2, 0xC7, 0xAB, 0x59, 0x23, 0x3A,  // [....Y#:
                        /* 0F68 */  0x03, 0xD5, 0x45, 0x42, 0x64, 0x65, 0xC4, 0xC5,  // ..EBde..
                        /* 0F70 */  0x7C, 0xD2, 0xFD, 0x6D, 0x2D, 0x25, 0xBE, 0x6D,  // |..m-%.m
                        /* 0F78 */  0x80, 0x7F, 0x95, 0x52, 0xD9, 0xE1, 0x3F, 0xF8,  // ...R..?.
                        /* 0F80 */  0x4A, 0x76, 0x60, 0x7C, 0xDF, 0xF9, 0x01, 0xB4,  // Jv`|....
                        /* 0F88 */  0x31, 0x40, 0x86, 0xFD, 0x78, 0x2D, 0xDC, 0x88,  // 1@..x-..
                        /* 0F90 */  0xDB, 0x74, 0xA2, 0x2D, 0x30, 0x30, 0x80, 0x96,  // .t.-00..
                        /* 0F98 */  0xFB, 0xE8, 0x01, 0xF4, 0x61, 0xDD, 0xB2, 0xB5,  // ....a...
                        /* 0FA0 */  0x8F, 0x81, 0xF1, 0xB3, 0x5D, 0x9C, 0xC4, 0x0F,  // ....]...
                        /* 0FA8 */  0x01, 0xCB, 0xE7, 0x27, 0xD9, 0xA4, 0x96, 0x00,  // ...'....
                        /* 0FB0 */  0x54, 0x48, 0x53, 0xA4, 0x22, 0x12, 0x08, 0x86,  // THS."...
                        /* 0FB8 */  0x26, 0x08, 0xD8, 0xD6, 0x82, 0x1F, 0x58, 0xBD,  // &.....X.
                        /* 0FC0 */  0xEA, 0x92, 0x21, 0x0A, 0xB1, 0x9E, 0xB0, 0x8A,  // ..!.....
                        /* 0FC8 */  0xA7, 0x3F, 0x65, 0xE2, 0x95, 0x9A, 0xB9, 0x0C,  // .?e.....
                        /* 0FD0 */  0xFA, 0x0C, 0x73, 0x36, 0x19, 0xA2, 0xA5, 0x69,  // ..s6...i
                        /* 0FD8 */  0xCE, 0x19, 0x1E, 0x29, 0x92, 0x16, 0x4E, 0xFA,  // ...)..N.
                        /* 0FE0 */  0xF3, 0xD1, 0x96, 0x19, 0x1F, 0x39, 0xFF, 0x33,  // .....9.3
                        /* 0FE8 */  0xF5, 0xAF, 0xB6, 0x36, 0x05, 0x57, 0x9A, 0x5C,  // ...6.W.\
                        /* 0FF0 */  0x49, 0x1C, 0xD8, 0xE4, 0xCE, 0xFB, 0x70, 0xE9,  // I.....p.
                        /* 0FF8 */  0x6F, 0x89, 0x31, 0x8C, 0xEB, 0xAD, 0x57, 0x2C,  // o.1...W,
                        /* 1000 */  0x8F, 0xDE, 0x47, 0x2B, 0x4E, 0xFF, 0xB0, 0x7C,  // ..G+N..|
                        /* 1008 */  0x8B, 0x85, 0x89, 0xE2, 0x50, 0x87, 0x32, 0x3D,  // ....P.2=
                        /* 1010 */  0x2B, 0xBF, 0xA9, 0xE6, 0x84, 0x67, 0xEF, 0xEA,  // +....g..
                        /* 1018 */  0xF2, 0x77, 0x5B, 0xF2, 0xCD, 0xD2, 0xFC, 0x52,  // .w[....R
                        /* 1020 */  0xD6, 0x13, 0x6F, 0x41, 0xCF, 0x84, 0xCE, 0xF9,  // ..oA....
                        /* 1028 */  0x2E, 0xD1, 0x5D, 0x7F, 0x78, 0x39, 0xD2, 0x2B,  // ..].x9.+
                        /* 1030 */  0x69, 0xE7, 0x55, 0x1D, 0x5B, 0x7A, 0xFF, 0x7B,  // i.U.[z.{
                        /* 1038 */  0x5E, 0xB0, 0xB3, 0x2B, 0x32, 0x9E, 0xF9, 0x0D,  // ^..+2...
                        /* 1040 */  0x56, 0x4C, 0xC4, 0x95, 0x12, 0x43, 0xC4, 0xF0,  // VL...C..
                        /* 1048 */  0xAC, 0x26, 0xA3, 0x70, 0x95, 0x01, 0xE5, 0xB9,  // .&.p....
                        /* 1050 */  0xAE, 0xBF, 0xFF, 0xF6, 0x23, 0xF7, 0x2C, 0x8B,  // ....#.,.
                        /* 1058 */  0x92, 0x7D, 0xC1, 0xD3, 0xEF, 0x03, 0x17, 0x4D,  // .}.....M
                        /* 1060 */  0xC6, 0x65, 0x83, 0x5B, 0x4C, 0xD2, 0x84, 0x8E,  // .e.[L...
                        /* 1068 */  0xBB, 0xC3, 0x74, 0xB8, 0x85, 0xF2, 0x94, 0x2A,  // ..t....*
                        /* 1070 */  0xAB, 0x9C, 0x82, 0xA9, 0xF8, 0x40, 0x91, 0x04,  // .....@..
                        /* 1078 */  0xD4, 0x09, 0xD5, 0xEE, 0x4C, 0x3D, 0x12, 0xCA,  // ....L=..
                        /* 1080 */  0xD0, 0x2A, 0x8C, 0xA1, 0xB3, 0x07, 0x5D, 0xE0,  // .*....].
                        /* 1088 */  0xFD, 0x2E, 0x37, 0xC0, 0x75, 0x1E, 0xF6, 0x0F,  // ..7.u...
                        /* 1090 */  0xE0, 0x49, 0x4B, 0x6D, 0x6D, 0xD9, 0x9C, 0x2C,  // .IKmm..,
                        /* 1098 */  0x1A, 0xD4, 0x76, 0x17, 0xE1, 0x15, 0xB5, 0xB0,  // ..v.....
                        /* 10A0 */  0xC5, 0x1A, 0x35, 0xDE, 0xEC, 0x7D, 0x04, 0x18,  // ..5..}..
                        /* 10A8 */  0x49, 0x2A, 0x1A, 0x50, 0x9A, 0x25, 0x1A, 0x52,  // I*.P.%.R
                        /* 10B0 */  0x60, 0x63, 0x46, 0x49, 0x8F, 0xB4, 0x98, 0x5C,  // `cFI...\
                        /* 10B8 */  0xCD, 0xB2, 0xFB, 0x5C, 0x1A, 0x7A, 0xAE, 0xC7,  // ...\.z..
                        /* 10C0 */  0xAE, 0x51, 0x8C, 0x05, 0x40, 0x77, 0x99, 0x5F,  // .Q..@w._
                        /* 10C8 */  0x60, 0x25, 0xA4, 0x1D, 0xF8, 0x83, 0x3C, 0x94,  // `%....<.
                        /* 10D0 */  0x67, 0xF8, 0x95, 0xD4, 0xD6, 0xD8, 0xDE, 0x5F,  // g......_
                        /* 10D8 */  0x67, 0xED, 0x7F, 0xD7, 0x3B, 0x22, 0x2D, 0xB8,  // g...;"-.
                        /* 10E0 */  0xD2, 0x25, 0x18, 0x1C, 0x90, 0x7E, 0x4A         // .%...~J
                    }
                })
            }
        }
    }

    Scope (\_SB)
    {
        Device (SEN1)
        {
            Name (_UID, "SEN1")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.IETM.GHID (_UID))
            }

            Name (_STR, Unicode ("Thermistor CPU SOC"))  // _STR: Description String
            Name (PTYP, 0x03)
            Name (CTYP, Zero)
            Name (PFLG, Zero)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }

            Name (ECTP, Zero)
            Name (RCEO, Zero)
            Name (WAAR, Zero)
            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                If ((\_SB.PC00.LPCB.EC0.LPL1 == One))
                {
                    \_SB.PC00.LPCB.EC0.LPL1 = Zero
                    Sleep (0x10)
                    \_SB.PC00.LPCB.EC0.TDPS = One
                }

                Return (\_SB.IETM.CTOK (\_SB.PC00.LPCB.EC0.STM0))
            }

            Name (PATC, 0x02)
            Method (PAT0, 1, Serialized)
            {
            }

            Method (PAT1, 1, Serialized)
            {
            }

            Name (GTSH, 0x14)
            Name (LSTM, Zero)
            Method (_DTI, 1, NotSerialized)  // _DTI: Device Temperature Indication
            {
                LSTM = Arg0
                Notify (\_SB.SEN1, 0x91) // Device-Specific
            }

            Method (_NTT, 0, NotSerialized)  // _NTT: Notification Temperature Threshold
            {
                Return (0x0ADE)
            }

            Name (S1AC, 0x3C)
            Name (S1A1, 0x32)
            Name (S1A2, 0x28)
            Name (S1PV, 0x41)
            Name (S1CC, 0x50)
            Name (S1C3, 0x46)
            Name (S1HP, 0x4B)
            Name (SSP1, 0x0A)
            Method (_TSP, 0, Serialized)  // _TSP: Thermal Sampling Period
            {
                Return (SSP1) /* \_SB_.SEN1.SSP1 */
            }

            Method (_AC0, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Local1 = \_SB.IETM.CTOK (S1AC)
                If ((LSTM >= Local1))
                {
                    Return ((Local1 - 0x14))
                }
                Else
                {
                    Return (Local1)
                }
            }

            Method (_AC1, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S1A1))
            }

            Method (_AC2, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S1A2))
            }

            Method (_PSV, 0, Serialized)  // _PSV: Passive Temperature
            {
                Return (\_SB.IETM.CTOK (S1PV))
            }

            Method (_CRT, 0, Serialized)  // _CRT: Critical Temperature
            {
                Return (\_SB.IETM.CTOK (S1CC))
            }

            Method (_CR3, 0, Serialized)  // _CR3: Warm/Standby Temperature
            {
                Return (\_SB.IETM.CTOK (S1C3))
            }

            Method (_HOT, 0, Serialized)  // _HOT: Hot Temperature
            {
                Return (\_SB.IETM.CTOK (S1HP))
            }
        }
    }

    Scope (\_SB)
    {
        Device (SEN2)
        {
            Name (_UID, "SEN2")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.IETM.GHID (_UID))
            }

            Name (_STR, Unicode ("Sensor 2 TS_Local"))  // _STR: Description String
            Name (PTYP, 0x03)
            Name (CTYP, Zero)
            Name (PFLG, Zero)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }

            Name (ECTP, Zero)
            Name (RCEO, Zero)
            Name (WAAR, Zero)
            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                If ((\_SB.PC00.LPCB.EC0.LPL1 == One))
                {
                    \_SB.PC00.LPCB.EC0.LPL1 = Zero
                    Sleep (0x10)
                    \_SB.PC00.LPCB.EC0.TDPS = One
                }

                Return (\_SB.IETM.CTOK (\_SB.PC00.LPCB.EC0.SYST))
            }

            Name (PATC, 0x02)
            Method (PAT0, 1, Serialized)
            {
                \_SB.PC00.LPCB.EC0.PG1D = \_SB.IETM.KTOC (Arg0)
            }

            Method (PAT1, 1, Serialized)
            {
                \_SB.PC00.LPCB.EC0.PG1U = \_SB.IETM.KTOC (Arg0)
            }

            Name (GTSH, 0x14)
            Name (LSTM, Zero)
            Method (_DTI, 1, NotSerialized)  // _DTI: Device Temperature Indication
            {
                LSTM = Arg0
                Notify (\_SB.SEN2, 0x91) // Device-Specific
            }

            Method (_NTT, 0, NotSerialized)  // _NTT: Notification Temperature Threshold
            {
                Return (0x0ADE)
            }

            Name (S2AC, 0x3C)
            Name (S2A1, 0x32)
            Name (S2A2, 0x28)
            Name (S2PV, 0x41)
            Name (S2CC, 0x50)
            Name (S2C3, 0x46)
            Name (S2HP, 0x4B)
            Name (SSP2, 0x0A)
            Method (_TSP, 0, Serialized)  // _TSP: Thermal Sampling Period
            {
                Return (SSP2) /* \_SB_.SEN2.SSP2 */
            }

            Method (_AC0, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Local1 = \_SB.IETM.CTOK (S2AC)
                If ((LSTM >= Local1))
                {
                    Return ((Local1 - 0x14))
                }
                Else
                {
                    Return (Local1)
                }
            }

            Method (_AC1, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S2A1))
            }

            Method (_AC2, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S2A2))
            }

            Method (_PSV, 0, Serialized)  // _PSV: Passive Temperature
            {
                Return (\_SB.IETM.CTOK (S2PV))
            }

            Method (_CRT, 0, Serialized)  // _CRT: Critical Temperature
            {
                Return (\_SB.IETM.CTOK (S2CC))
            }

            Method (_CR3, 0, Serialized)  // _CR3: Warm/Standby Temperature
            {
                Return (\_SB.IETM.CTOK (S2C3))
            }

            Method (_HOT, 0, Serialized)  // _HOT: Hot Temperature
            {
                Return (\_SB.IETM.CTOK (S2HP))
            }
        }
    }

    Scope (\_SB)
    {
        Device (SEN3)
        {
            Name (_UID, "SEN3")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.IETM.GHID (_UID))
            }

            Name (_STR, Unicode ("Sensor 3 TS_Remote"))  // _STR: Description String
            Name (PTYP, 0x03)
            Name (CTYP, Zero)
            Name (PFLG, Zero)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }

            Name (ECTP, Zero)
            Name (RCEO, Zero)
            Name (WAAR, Zero)
            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                If ((\_SB.PC00.LPCB.EC0.LPL1 == One))
                {
                    \_SB.PC00.LPCB.EC0.LPL1 = Zero
                    Sleep (0x10)
                    \_SB.PC00.LPCB.EC0.TDPS = One
                }

                Return (\_SB.IETM.CTOK (\_SB.PC00.LPCB.EC0.PCHT))
            }

            Name (PATC, 0x02)
            Method (PAT0, 1, Serialized)
            {
            }

            Method (PAT1, 1, Serialized)
            {
            }

            Name (GTSH, 0x14)
            Name (LSTM, Zero)
            Method (_DTI, 1, NotSerialized)  // _DTI: Device Temperature Indication
            {
                LSTM = Arg0
                Notify (\_SB.SEN3, 0x91) // Device-Specific
            }

            Method (_NTT, 0, NotSerialized)  // _NTT: Notification Temperature Threshold
            {
                Return (0x0ADE)
            }

            Name (S3AC, 0x3C)
            Name (S3A1, 0x32)
            Name (S3A2, 0x28)
            Name (S3PV, 0x41)
            Name (S3CC, 0x50)
            Name (S3C3, 0x46)
            Name (S3HP, 0x4B)
            Name (SSP3, 0x0A)
            Method (_TSP, 0, Serialized)  // _TSP: Thermal Sampling Period
            {
                Return (SSP3) /* \_SB_.SEN3.SSP3 */
            }

            Method (_AC3, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Local1 = \_SB.IETM.CTOK (S3AC)
                If ((LSTM >= Local1))
                {
                    Return ((Local1 - 0x14))
                }
                Else
                {
                    Return (Local1)
                }
            }

            Method (_AC4, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S3A1))
            }

            Method (_AC5, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S3A2))
            }

            Method (_PSV, 0, Serialized)  // _PSV: Passive Temperature
            {
                Return (\_SB.IETM.CTOK (S3PV))
            }

            Method (_CRT, 0, Serialized)  // _CRT: Critical Temperature
            {
                Return (\_SB.IETM.CTOK (S3CC))
            }

            Method (_CR3, 0, Serialized)  // _CR3: Warm/Standby Temperature
            {
                Return (\_SB.IETM.CTOK (S3C3))
            }

            Method (_HOT, 0, Serialized)  // _HOT: Hot Temperature
            {
                Return (\_SB.IETM.CTOK (S3HP))
            }
        }
    }

    Scope (\_SB)
    {
        Device (SEN4)
        {
            Name (_UID, "SEN4")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.IETM.GHID (_UID))
            }

            Name (_STR, Unicode ("Sensor 4 GPU"))  // _STR: Description String
            Name (PTYP, 0x03)
            Name (CTYP, Zero)
            Name (PFLG, Zero)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }

            Name (ECTP, Zero)
            Name (RCEO, Zero)
            Name (WAAR, Zero)
            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                If ((\_SB.PC00.LPCB.EC0.LPL1 == One))
                {
                    \_SB.PC00.LPCB.EC0.LPL1 = Zero
                    Sleep (0x10)
                    \_SB.PC00.LPCB.EC0.TDPS = One
                }

                Return (\_SB.IETM.CTOK (\_SB.PC00.LPCB.EC0.VGET))
            }

            Name (PATC, 0x02)
            Method (PAT0, 1, Serialized)
            {
                \_SB.PC00.LPCB.EC0.PG3D = \_SB.IETM.KTOC (Arg0)
            }

            Method (PAT1, 1, Serialized)
            {
                \_SB.PC00.LPCB.EC0.PG3D = \_SB.IETM.KTOC (Arg0)
            }

            Name (GTSH, 0x14)
            Name (LSTM, Zero)
            Method (_DTI, 1, NotSerialized)  // _DTI: Device Temperature Indication
            {
                LSTM = Arg0
                Notify (\_SB.SEN4, 0x91) // Device-Specific
            }

            Method (_NTT, 0, NotSerialized)  // _NTT: Notification Temperature Threshold
            {
                Return (0x0ADE)
            }

            Name (S4AC, 0x3C)
            Name (S4A1, 0x32)
            Name (S4A2, 0x28)
            Name (S4PV, 0x41)
            Name (S4CC, 0x50)
            Name (S4C3, 0x46)
            Name (S4HP, 0x4B)
            Name (SSP4, 0x0A)
            Method (_TSP, 0, Serialized)  // _TSP: Thermal Sampling Period
            {
                Return (SSP4) /* \_SB_.SEN4.SSP4 */
            }

            Method (_AC0, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Local1 = \_SB.IETM.CTOK (S4AC)
                If ((LSTM >= Local1))
                {
                    Return ((Local1 - 0x14))
                }
                Else
                {
                    Return (Local1)
                }
            }

            Method (_AC1, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S4A1))
            }

            Method (_AC2, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S4A2))
            }

            Method (_PSV, 0, Serialized)  // _PSV: Passive Temperature
            {
                Return (\_SB.IETM.CTOK (S4PV))
            }

            Method (_CRT, 0, Serialized)  // _CRT: Critical Temperature
            {
                Return (\_SB.IETM.CTOK (S4CC))
            }

            Method (_CR3, 0, Serialized)  // _CR3: Warm/Standby Temperature
            {
                Return (\_SB.IETM.CTOK (S4C3))
            }

            Method (_HOT, 0, Serialized)  // _HOT: Hot Temperature
            {
                Return (\_SB.IETM.CTOK (S4HP))
            }
        }
    }

    Scope (\_SB)
    {
        Device (SEN5)
        {
            Name (_UID, "SEN5")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.IETM.GHID (_UID))
            }

            Name (_STR, Unicode ("Thermistor USB Type-C"))  // _STR: Description String
            Name (PTYP, 0x03)
            Name (CTYP, Zero)
            Name (PFLG, Zero)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }

            Name (ECTP, Zero)
            Name (RCEO, Zero)
            Name (WAAR, Zero)
            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                If ((\_SB.PC00.LPCB.EC0.LPL1 == One))
                {
                    \_SB.PC00.LPCB.EC0.LPL1 = Zero
                    Sleep (0x10)
                    \_SB.PC00.LPCB.EC0.TDPS = One
                }

                Return (\_SB.IETM.CTOK (\_SB.PC00.LPCB.EC0.TNTC))
            }

            Name (PATC, 0x02)
            Method (PAT0, 1, Serialized)
            {
                \_SB.PC00.LPCB.EC0.PG4D = \_SB.IETM.KTOC (Arg0)
            }

            Method (PAT1, 1, Serialized)
            {
                \_SB.PC00.LPCB.EC0.PG4U = \_SB.IETM.KTOC (Arg0)
            }

            Name (GTSH, 0x14)
            Name (LSTM, Zero)
            Method (_DTI, 1, NotSerialized)  // _DTI: Device Temperature Indication
            {
                LSTM = Arg0
                Notify (\_SB.SEN5, 0x91) // Device-Specific
            }

            Method (_NTT, 0, NotSerialized)  // _NTT: Notification Temperature Threshold
            {
                Return (0x0ADE)
            }

            Name (S5AC, 0x3C)
            Name (S5A1, 0x32)
            Name (S5A2, 0x28)
            Name (S5PV, 0x41)
            Name (S5CC, 0x50)
            Name (S5C3, 0x46)
            Name (S5HP, 0x4B)
            Name (SSP5, 0x0A)
            Method (_TSP, 0, Serialized)  // _TSP: Thermal Sampling Period
            {
                Return (SSP5) /* \_SB_.SEN5.SSP5 */
            }

            Method (_AC0, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Local1 = \_SB.IETM.CTOK (S5AC)
                If ((LSTM >= Local1))
                {
                    Return ((Local1 - 0x14))
                }
                Else
                {
                    Return (Local1)
                }
            }

            Method (_AC1, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S5A1))
            }

            Method (_AC2, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S5A2))
            }

            Method (_PSV, 0, Serialized)  // _PSV: Passive Temperature
            {
                Return (\_SB.IETM.CTOK (S5PV))
            }

            Method (_CRT, 0, Serialized)  // _CRT: Critical Temperature
            {
                Return (\_SB.IETM.CTOK (S5CC))
            }

            Method (_CR3, 0, Serialized)  // _CR3: Warm/Standby Temperature
            {
                Return (\_SB.IETM.CTOK (S5C3))
            }

            Method (_HOT, 0, Serialized)  // _HOT: Hot Temperature
            {
                Return (\_SB.IETM.CTOK (S5HP))
            }
        }
    }

    Scope (\_SB)
    {
        Device (SEN6)
        {
            Name (_UID, "SEN6")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.IETM.GHID (_UID))
            }

            Name (_STR, Unicode ("Charger Temperature"))  // _STR: Description String
            Name (PTYP, 0x03)
            Name (CTYP, Zero)
            Name (PFLG, Zero)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }

            Name (ECTP, Zero)
            Name (RCEO, Zero)
            Name (WAAR, Zero)
            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                If ((\_SB.PC00.LPCB.EC0.LPL1 == One))
                {
                    \_SB.PC00.LPCB.EC0.LPL1 = Zero
                    Sleep (0x10)
                    \_SB.PC00.LPCB.EC0.TDPS = One
                }

                Return (\_SB.IETM.CTOK (\_SB.PC00.LPCB.EC0.CNTC))
            }

            Name (PATC, 0x02)
            Method (PAT0, 1, Serialized)
            {
            }

            Method (PAT1, 1, Serialized)
            {
            }

            Name (GTSH, 0x14)
            Name (LSTM, Zero)
            Method (_DTI, 1, NotSerialized)  // _DTI: Device Temperature Indication
            {
                LSTM = Arg0
                Notify (\_SB.SEN6, 0x91) // Device-Specific
            }

            Method (_NTT, 0, NotSerialized)  // _NTT: Notification Temperature Threshold
            {
                Return (0x0ADE)
            }

            Name (S6AC, 0x3C)
            Name (S6A1, 0x32)
            Name (S6A2, 0x28)
            Name (S6PV, 0x41)
            Name (S6CC, 0x50)
            Name (S6C3, 0x46)
            Name (S6HP, 0x4B)
            Name (SSP6, 0x0A)
            Method (_TSP, 0, Serialized)  // _TSP: Thermal Sampling Period
            {
                Return (SSP6) /* \_SB_.SEN6.SSP6 */
            }

            Method (_AC0, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Local1 = \_SB.IETM.CTOK (S6AC)
                If ((LSTM >= Local1))
                {
                    Return ((Local1 - 0x14))
                }
                Else
                {
                    Return (Local1)
                }
            }

            Method (_AC1, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S6A1))
            }

            Method (_AC2, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S6A2))
            }

            Method (_PSV, 0, Serialized)  // _PSV: Passive Temperature
            {
                Return (\_SB.IETM.CTOK (S6PV))
            }

            Method (_CRT, 0, Serialized)  // _CRT: Critical Temperature
            {
                Return (\_SB.IETM.CTOK (S6CC))
            }

            Method (_CR3, 0, Serialized)  // _CR3: Warm/Standby Temperature
            {
                Return (\_SB.IETM.CTOK (S6C3))
            }

            Method (_HOT, 0, Serialized)  // _HOT: Hot Temperature
            {
                Return (\_SB.IETM.CTOK (S6HP))
            }
        }
    }

    Scope (\_SB)
    {
        Device (SEN7)
        {
            Name (_UID, "SEN7")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.IETM.GHID (_UID))
            }

            Name (_STR, Unicode ("Battery Temperature"))  // _STR: Description String
            Name (PTYP, 0x03)
            Name (CTYP, Zero)
            Name (PFLG, Zero)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                Return (0x0F)
            }

            Name (ECTP, Zero)
            Name (RCEO, Zero)
            Name (WAAR, Zero)
            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                If ((\_SB.PC00.LPCB.EC0.LPL1 == One))
                {
                    \_SB.PC00.LPCB.EC0.LPL1 = Zero
                    Sleep (0x10)
                    \_SB.PC00.LPCB.EC0.TDPS = One
                }

                Return (\_SB.IETM.CTOK (\_SB.PC00.LPCB.EC0.BTTL))
            }

            Name (PATC, 0x02)
            Method (PAT0, 1, Serialized)
            {
            }

            Method (PAT1, 1, Serialized)
            {
            }

            Name (GTSH, 0x14)
            Name (LSTM, Zero)
            Method (_DTI, 1, NotSerialized)  // _DTI: Device Temperature Indication
            {
                LSTM = Arg0
                Notify (\_SB.SEN7, 0x91) // Device-Specific
            }

            Method (_NTT, 0, NotSerialized)  // _NTT: Notification Temperature Threshold
            {
                Return (0x0ADE)
            }

            Name (S7AC, 0x3C)
            Name (S7A1, 0x32)
            Name (S7A2, 0x28)
            Name (S7PV, 0x41)
            Name (S7CC, 0x50)
            Name (S7C3, 0x46)
            Name (S7HP, 0x4B)
            Name (SSP7, 0x0A)
            Method (_TSP, 0, Serialized)  // _TSP: Thermal Sampling Period
            {
                Return (SSP7) /* \_SB_.SEN7.SSP7 */
            }

            Method (_AC0, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Local1 = \_SB.IETM.CTOK (S7AC)
                If ((LSTM >= Local1))
                {
                    Return ((Local1 - 0x14))
                }
                Else
                {
                    Return (Local1)
                }
            }

            Method (_AC1, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S7A1))
            }

            Method (_AC2, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S7A2))
            }

            Method (_PSV, 0, Serialized)  // _PSV: Passive Temperature
            {
                Return (\_SB.IETM.CTOK (S7PV))
            }

            Method (_CRT, 0, Serialized)  // _CRT: Critical Temperature
            {
                Return (\_SB.IETM.CTOK (S7CC))
            }

            Method (_CR3, 0, Serialized)  // _CR3: Warm/Standby Temperature
            {
                Return (\_SB.IETM.CTOK (S7C3))
            }

            Method (_HOT, 0, Serialized)  // _HOT: Hot Temperature
            {
                Return (\_SB.IETM.CTOK (S7HP))
            }
        }
    }

    Scope (\_SB.IETM)
    {
        Name (PTTL, 0x14)
        Name (PSVT, Package (0x05)
        {
            0x02, 
            Package (0x0C)
            {
                \_SB.PC00.TCPU, 
                \_SB.PC00.TCPU, 
                0x09, 
                0x64, 
                0x0D4A, 
                0x09, 
                0x00010000, 
                "MAX", 
                0x01F4, 
                0x0A, 
                0x14, 
                Zero
            }, 

            Package (0x0C)
            {
                \_SB.PC00.TCPU, 
                \_SB.SEN2, 
                0x08, 
                0xC8, 
                0x0D68, 
                0x09, 
                0x00010000, 
                "MAX", 
                0xFA, 
                0x0A, 
                0x14, 
                Zero
            }, 

            Package (0x0C)
            {
                \_SB.PC00.TCPU, 
                \_SB.SEN3, 
                0x07, 
                0x64, 
                0x0DCC, 
                0x09, 
                0x00010000, 
                "MAX", 
                0xFA, 
                0x0A, 
                0x14, 
                Zero
            }, 

            Package (0x0C)
            {
                \_SB.PC00.TCPU, 
                \_SB.SEN4, 
                0x06, 
                0xC8, 
                0x0DCC, 
                0x09, 
                0x00010000, 
                "MAX", 
                0xFA, 
                0x0A, 
                0x14, 
                Zero
            }
        })
    }

    Scope (\_SB.IETM)
    {
        Method (KTOC, 1, Serialized)
        {
            If ((Arg0 > 0x0AAC))
            {
                Return (((Arg0 - 0x0AAC) / 0x0A))
            }
            Else
            {
                Return (Zero)
            }
        }

        Method (CTOK, 1, Serialized)
        {
            Return (((Arg0 * 0x0A) + 0x0AAC))
        }

        Method (C10K, 1, Serialized)
        {
            Name (TMP1, Buffer (0x10)
            {
                 0x00                                             // .
            })
            CreateByteField (TMP1, Zero, TMPL)
            CreateByteField (TMP1, One, TMPH)
            Local0 = (Arg0 + 0x0AAC)
            TMPL = (Local0 & 0xFF)
            TMPH = ((Local0 & 0xFF00) >> 0x08)
            ToInteger (TMP1, Local1)
            Return (Local1)
        }

        Method (K10C, 1, Serialized)
        {
            If ((Arg0 > 0x0AAC))
            {
                Return ((Arg0 - 0x0AAC))
            }
            Else
            {
                Return (Zero)
            }
        }
    }

    Scope (\_SB.PC00.TCPU)
    {
        Name (PFLG, Zero)
        Method (_STA, 0, NotSerialized)  // _STA: Status
        {
            Return (0x0F)
        }

        OperationRegion (CPWR, SystemMemory, ((\_SB.PC00.MC.MHBR << 0x0F) + 0x5000), 0x1000)
        Field (CPWR, ByteAcc, NoLock, Preserve)
        {
            Offset (0x930), 
            PTDP,   15, 
            Offset (0x932), 
            PMIN,   15, 
            Offset (0x934), 
            PMAX,   15, 
            Offset (0x936), 
            TMAX,   7, 
            Offset (0x938), 
            PWRU,   4, 
            Offset (0x939), 
            EGYU,   5, 
            Offset (0x93A), 
            TIMU,   4, 
            Offset (0x958), 
            Offset (0x95C), 
            LPMS,   1, 
            CTNL,   2, 
            Offset (0x978), 
            PCTP,   8, 
            Offset (0x998), 
            RP0C,   8, 
            RP1C,   8, 
            RPNC,   8, 
            Offset (0xF3C), 
            TRAT,   8, 
            Offset (0xF40), 
            PTD1,   15, 
            Offset (0xF42), 
            TRA1,   8, 
            Offset (0xF44), 
            PMX1,   15, 
            Offset (0xF46), 
            PMN1,   15, 
            Offset (0xF48), 
            PTD2,   15, 
            Offset (0xF4A), 
            TRA2,   8, 
            Offset (0xF4C), 
            PMX2,   15, 
            Offset (0xF4E), 
            PMN2,   15, 
            Offset (0xF50), 
            CTCL,   2, 
                ,   29, 
            CLCK,   1, 
            MNTR,   8
        }

        Name (XPCC, Zero)
        Method (PPCC, 0, Serialized)
        {
            If (((XPCC == Zero) && CondRefOf (\_SB.CBMI)))
            {
                Switch (ToInteger (\_SB.CBMI))
                {
                    Case (Zero)
                    {
                        If (((\_SB.CLVL >= One) && (\_SB.CLVL <= 0x03)))
                        {
                            CPL0 ()
                            XPCC = One
                        }
                    }
                    Case (One)
                    {
                        If (((\_SB.CLVL == 0x02) || (\_SB.CLVL == 0x03)))
                        {
                            CPL1 ()
                            XPCC = One
                        }
                    }
                    Case (0x02)
                    {
                        If ((\_SB.CLVL == 0x03))
                        {
                            CPL2 ()
                            XPCC = One
                        }
                    }

                }
            }

            Return (NPCC) /* \_SB_.PC00.TCPU.NPCC */
        }

        Name (NPCC, Package (0x03)
        {
            0x02, 
            Package (0x06)
            {
                Zero, 
                0x61A8, 
                0x61A8, 
                0x6D60, 
                0x6D60, 
                0xFA
            }, 

            Package (0x06)
            {
                One, 
                0xC738, 
                0xC738, 
                0x6D60, 
                0x6D60, 
                0xFA
            }
        })
        Method (CPNU, 2, Serialized)
        {
            Name (CNVT, Zero)
            Name (PPUU, Zero)
            Name (RMDR, Zero)
            If ((PWRU == Zero))
            {
                PPUU = One
            }
            Else
            {
                PPUU = (PWRU-- << 0x02)
            }

            Divide (Arg0, PPUU, RMDR, CNVT) /* \_SB_.PC00.TCPU.CPNU.CNVT */
            If ((Arg1 == Zero))
            {
                Return (CNVT) /* \_SB_.PC00.TCPU.CPNU.CNVT */
            }
            Else
            {
                CNVT *= 0x03E8
                RMDR *= 0x03E8
                RMDR /= PPUU
                CNVT += RMDR /* \_SB_.PC00.TCPU.CPNU.RMDR */
                Return (CNVT) /* \_SB_.PC00.TCPU.CPNU.CNVT */
            }
        }

        Method (CPL0, 0, NotSerialized)
        {
            \_SB.PC00.TCPU.NPCC [Zero] = 0x02
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [Zero] = Zero
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [One] = 0x61A8
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x02] = 0x61A8
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x03] = 0xDAC0
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x04] = 0xDAC0
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x05] = 0xFA
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [Zero] = One
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [One] = 0xC738
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x02] = 0xC738
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x03] = 0xDAC0
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x04] = 0xDAC0
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x05] = 0xFA
        }

        Method (CPL1, 0, NotSerialized)
        {
            \_SB.PC00.TCPU.NPCC [Zero] = 0x02
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [Zero] = Zero
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [One] = 0x61A8
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x02] = 0x61A8
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x03] = 0xDAC0
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x04] = 0xDAC0
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x05] = 0xFA
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [Zero] = One
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [One] = 0xC738
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x02] = 0xC738
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x03] = 0xDAC0
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x04] = 0xDAC0
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x05] = 0xFA
        }

        Method (CPL2, 0, NotSerialized)
        {
            \_SB.PC00.TCPU.NPCC [Zero] = 0x02
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [Zero] = Zero
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [One] = 0x61A8
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x02] = 0x61A8
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x03] = 0xDAC0
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x04] = 0xDAC0
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x05] = 0xFA
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [Zero] = One
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [One] = 0xC738
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x02] = 0xC738
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x03] = 0xDAC0
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x04] = 0xDAC0
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x05] = 0xFA
        }

        Name (LSTM, Zero)
        Name (_PPC, Zero)  // _PPC: Performance Present Capabilities
        Method (SPPC, 1, Serialized)
        {
            If (CondRefOf (\_SB.CPPC))
            {
                \_SB.CPPC = Arg0
            }

            If ((ToInteger (\TCNT) > Zero))
            {
                Notify (\_SB.PR00, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > One))
            {
                Notify (\_SB.PR01, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x02))
            {
                Notify (\_SB.PR02, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x03))
            {
                Notify (\_SB.PR03, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x04))
            {
                Notify (\_SB.PR04, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x05))
            {
                Notify (\_SB.PR05, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x06))
            {
                Notify (\_SB.PR06, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x07))
            {
                Notify (\_SB.PR07, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x08))
            {
                Notify (\_SB.PR08, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x09))
            {
                Notify (\_SB.PR09, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x0A))
            {
                Notify (\_SB.PR10, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x0B))
            {
                Notify (\_SB.PR11, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x0C))
            {
                Notify (\_SB.PR12, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x0D))
            {
                Notify (\_SB.PR13, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x0E))
            {
                Notify (\_SB.PR14, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x0F))
            {
                Notify (\_SB.PR15, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x10))
            {
                Notify (\_SB.PR16, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x11))
            {
                Notify (\_SB.PR17, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x12))
            {
                Notify (\_SB.PR18, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x13))
            {
                Notify (\_SB.PR19, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x14))
            {
                Notify (\_SB.PR20, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x15))
            {
                Notify (\_SB.PR21, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x16))
            {
                Notify (\_SB.PR22, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x17))
            {
                Notify (\_SB.PR23, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x18))
            {
                Notify (\_SB.PR24, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x19))
            {
                Notify (\_SB.PR25, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x1A))
            {
                Notify (\_SB.PR26, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x1B))
            {
                Notify (\_SB.PR27, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x1C))
            {
                Notify (\_SB.PR28, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x1D))
            {
                Notify (\_SB.PR29, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x1E))
            {
                Notify (\_SB.PR30, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x1F))
            {
                Notify (\_SB.PR31, 0x80) // Status Change
            }
        }

        Method (SPUR, 1, NotSerialized)
        {
            If ((Arg0 <= \TCNT))
            {
                If ((\_SB.PAGD._STA () == 0x0F))
                {
                    \_SB.PAGD._PUR [One] = Arg0
                    Notify (\_SB.PAGD, 0x80) // Status Change
                }
            }
        }

        Method (PCCC, 0, Serialized)
        {
            PCCX [Zero] = One
            Switch (ToInteger (CPNU (PTDP, Zero)))
            {
                Case (0x39)
                {
                    DerefOf (PCCX [One]) [Zero] = 0xA7F8
                    DerefOf (PCCX [One]) [One] = 0x00017318
                }
                Case (0x2F)
                {
                    DerefOf (PCCX [One]) [Zero] = 0x9858
                    DerefOf (PCCX [One]) [One] = 0x00014C08
                }
                Case (0x25)
                {
                    DerefOf (PCCX [One]) [Zero] = 0x7148
                    DerefOf (PCCX [One]) [One] = 0xD6D8
                }
                Case (0x19)
                {
                    DerefOf (PCCX [One]) [Zero] = 0x3E80
                    DerefOf (PCCX [One]) [One] = 0x7D00
                }
                Case (0x0F)
                {
                    DerefOf (PCCX [One]) [Zero] = 0x36B0
                    DerefOf (PCCX [One]) [One] = 0x7D00
                }
                Case (0x0B)
                {
                    DerefOf (PCCX [One]) [Zero] = 0x36B0
                    DerefOf (PCCX [One]) [One] = 0x61A8
                }
                Default
                {
                    DerefOf (PCCX [One]) [Zero] = 0xFF
                    DerefOf (PCCX [One]) [One] = 0xFF
                }

            }

            Return (PCCX) /* \_SB_.PC00.TCPU.PCCX */
        }

        Name (PCCX, Package (0x02)
        {
            0x80000000, 
            Package (0x02)
            {
                0x80000000, 
                0x80000000
            }
        })
        Name (KEFF, Package (0x1E)
        {
            Package (0x02)
            {
                0x01BC, 
                Zero
            }, 

            Package (0x02)
            {
                0x01CF, 
                0x27
            }, 

            Package (0x02)
            {
                0x01E1, 
                0x4B
            }, 

            Package (0x02)
            {
                0x01F3, 
                0x6C
            }, 

            Package (0x02)
            {
                0x0206, 
                0x8B
            }, 

            Package (0x02)
            {
                0x0218, 
                0xA8
            }, 

            Package (0x02)
            {
                0x022A, 
                0xC3
            }, 

            Package (0x02)
            {
                0x023D, 
                0xDD
            }, 

            Package (0x02)
            {
                0x024F, 
                0xF4
            }, 

            Package (0x02)
            {
                0x0261, 
                0x010B
            }, 

            Package (0x02)
            {
                0x0274, 
                0x011F
            }, 

            Package (0x02)
            {
                0x032C, 
                0x01BD
            }, 

            Package (0x02)
            {
                0x03D7, 
                0x0227
            }, 

            Package (0x02)
            {
                0x048B, 
                0x026D
            }, 

            Package (0x02)
            {
                0x053E, 
                0x02A1
            }, 

            Package (0x02)
            {
                0x05F7, 
                0x02C6
            }, 

            Package (0x02)
            {
                0x06A8, 
                0x02E6
            }, 

            Package (0x02)
            {
                0x075D, 
                0x02FF
            }, 

            Package (0x02)
            {
                0x0818, 
                0x0311
            }, 

            Package (0x02)
            {
                0x08CF, 
                0x0322
            }, 

            Package (0x02)
            {
                0x179C, 
                0x0381
            }, 

            Package (0x02)
            {
                0x2DDC, 
                0x039C
            }, 

            Package (0x02)
            {
                0x44A8, 
                0x039E
            }, 

            Package (0x02)
            {
                0x5C35, 
                0x0397
            }, 

            Package (0x02)
            {
                0x747D, 
                0x038D
            }, 

            Package (0x02)
            {
                0x8D7F, 
                0x0382
            }, 

            Package (0x02)
            {
                0xA768, 
                0x0376
            }, 

            Package (0x02)
            {
                0xC23B, 
                0x0369
            }, 

            Package (0x02)
            {
                0xDE26, 
                0x035A
            }, 

            Package (0x02)
            {
                0xFB7C, 
                0x034A
            }
        })
        Name (CEUP, Package (0x06)
        {
            0x80000000, 
            0x80000000, 
            0x80000000, 
            0x80000000, 
            0x80000000, 
            0x80000000
        })
        Method (_DTI, 1, NotSerialized)  // _DTI: Device Temperature Indication
        {
            LSTM = Arg0
            Notify (\_SB.PC00.TCPU, 0x91) // Device-Specific
        }

        Method (_NTT, 0, NotSerialized)  // _NTT: Notification Temperature Threshold
        {
            Return (0x0ADE)
        }

        Name (PTYP, Zero)
        Method (_PSS, 0, NotSerialized)  // _PSS: Performance Supported States
        {
            If (CondRefOf (\_SB.PR00._PSS))
            {
                Return (\_SB.PR00._PSS ())
            }
            Else
            {
                Return (Package (0x02)
                {
                    Package (0x06)
                    {
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero
                    }, 

                    Package (0x06)
                    {
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero
                    }
                })
            }
        }

        Method (_TSS, 0, NotSerialized)  // _TSS: Throttling Supported States
        {
            If (CondRefOf (\_SB.PR00._TSS))
            {
                Return (\_SB.PR00._TSS ())
            }
            Else
            {
                Return (Package (0x01)
                {
                    Package (0x05)
                    {
                        One, 
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero
                    }
                })
            }
        }

        Method (_TPC, 0, NotSerialized)  // _TPC: Throttling Present Capabilities
        {
            If (CondRefOf (\_SB.PR00._TPC))
            {
                Return (\_SB.PR00._TPC) /* External reference */
            }
            Else
            {
                Return (Zero)
            }
        }

        Method (_PTC, 0, NotSerialized)  // _PTC: Processor Throttling Control
        {
            If ((CondRefOf (\PF00) && (\PF00 != 0x80000000)))
            {
                If ((\PF00 & 0x04))
                {
                    Return (Package (0x02)
                    {
                        ResourceTemplate ()
                        {
                            Register (FFixedHW, 
                                0x00,               // Bit Width
                                0x00,               // Bit Offset
                                0x0000000000000000, // Address
                                ,)
                        }, 

                        ResourceTemplate ()
                        {
                            Register (FFixedHW, 
                                0x00,               // Bit Width
                                0x00,               // Bit Offset
                                0x0000000000000000, // Address
                                ,)
                        }
                    })
                }
                Else
                {
                    Return (Package (0x02)
                    {
                        ResourceTemplate ()
                        {
                            Register (SystemIO, 
                                0x05,               // Bit Width
                                0x00,               // Bit Offset
                                0x0000000000001810, // Address
                                ,)
                        }, 

                        ResourceTemplate ()
                        {
                            Register (SystemIO, 
                                0x05,               // Bit Width
                                0x00,               // Bit Offset
                                0x0000000000001810, // Address
                                ,)
                        }
                    })
                }
            }
            Else
            {
                Return (Package (0x02)
                {
                    ResourceTemplate ()
                    {
                        Register (FFixedHW, 
                            0x00,               // Bit Width
                            0x00,               // Bit Offset
                            0x0000000000000000, // Address
                            ,)
                    }, 

                    ResourceTemplate ()
                    {
                        Register (FFixedHW, 
                            0x00,               // Bit Width
                            0x00,               // Bit Offset
                            0x0000000000000000, // Address
                            ,)
                    }
                })
            }
        }

        Method (_TSD, 0, NotSerialized)  // _TSD: Throttling State Dependencies
        {
            If (CondRefOf (\_SB.PR00._TSD))
            {
                Return (\_SB.PR00._TSD ())
            }
            Else
            {
                Return (Package (0x01)
                {
                    Package (0x05)
                    {
                        0x05, 
                        Zero, 
                        Zero, 
                        0xFC, 
                        Zero
                    }
                })
            }
        }

        Method (_TDL, 0, NotSerialized)  // _TDL: T-State Depth Limit
        {
            If ((CondRefOf (\_SB.PR00._TSS) && CondRefOf (\_SB.CFGD)))
            {
                If ((\_SB.CFGD & 0x2000))
                {
                    Return ((SizeOf (\_SB.PR00.TSMF) - One))
                }
                Else
                {
                    Return ((SizeOf (\_SB.PR00.TSMC) - One))
                }
            }
            Else
            {
                Return (Zero)
            }
        }

        Method (_PDL, 0, NotSerialized)  // _PDL: P-state Depth Limit
        {
            If (CondRefOf (\_SB.PR00._PSS))
            {
                If ((\_SB.OSCP & 0x0400))
                {
                    Return ((SizeOf (\_SB.PR00.TPSS) - One))
                }
                Else
                {
                    Return ((SizeOf (\_SB.PR00.LPSS) - One))
                }
            }
            Else
            {
                Return (Zero)
            }
        }

        Name (TJMX, 0x6E)
        Method (_TSP, 0, Serialized)  // _TSP: Thermal Sampling Period
        {
            Return (Zero)
        }

        Method (_AC0, 0, Serialized)  // _ACx: Active Cooling, x=0-9
        {
            Local1 = \_SB.IETM.CTOK (TJMX)
            Local1 -= 0x0A
            If ((LSTM >= Local1))
            {
                Return ((Local1 - 0x14))
            }
            Else
            {
                Return (Local1)
            }
        }

        Method (_AC1, 0, Serialized)  // _ACx: Active Cooling, x=0-9
        {
            Local1 = \_SB.IETM.CTOK (TJMX)
            Local1 -= 0x1E
            If ((LSTM >= Local1))
            {
                Return ((Local1 - 0x14))
            }
            Else
            {
                Return (Local1)
            }
        }

        Method (_AC2, 0, Serialized)  // _ACx: Active Cooling, x=0-9
        {
            Local1 = \_SB.IETM.CTOK (TJMX)
            Local1 -= 0x28
            If ((LSTM >= Local1))
            {
                Return ((Local1 - 0x14))
            }
            Else
            {
                Return (Local1)
            }
        }

        Method (_AC3, 0, Serialized)  // _ACx: Active Cooling, x=0-9
        {
            Local1 = \_SB.IETM.CTOK (TJMX)
            Local1 -= 0x37
            If ((LSTM >= Local1))
            {
                Return ((Local1 - 0x14))
            }
            Else
            {
                Return (Local1)
            }
        }

        Method (_AC4, 0, Serialized)  // _ACx: Active Cooling, x=0-9
        {
            Local1 = \_SB.IETM.CTOK (TJMX)
            Local1 -= 0x46
            If ((LSTM >= Local1))
            {
                Return ((Local1 - 0x14))
            }
            Else
            {
                Return (Local1)
            }
        }

        Method (_PSV, 0, Serialized)  // _PSV: Passive Temperature
        {
            Return (\_SB.IETM.CTOK (TJMX))
        }

        Method (_CRT, 0, Serialized)  // _CRT: Critical Temperature
        {
            Return (\_SB.IETM.CTOK (TJMX))
        }

        Method (_CR3, 0, Serialized)  // _CR3: Warm/Standby Temperature
        {
            Return (\_SB.IETM.CTOK (TJMX))
        }

        Method (_HOT, 0, Serialized)  // _HOT: Hot Temperature
        {
            Return (\_SB.IETM.CTOK (TJMX))
        }

        Method (UVTH, 1, Serialized)
        {
        }
    }

    Scope (\_SB.IETM)
    {
        Name (CTSP, Package (0x01)
        {
            ToUUID ("e145970a-e4c1-4d73-900e-c9c5a69dd067") /* Unknown UUID */
        })
    }

    Scope (\_SB.PC00.TCPU)
    {
        Method (TDPL, 0, Serialized)
        {
            Name (AAAA, Zero)
            Name (BBBB, Zero)
            Name (CCCC, Zero)
            Local0 = CTNL /* \_SB_.PC00.TCPU.CTNL */
            If (((Local0 == One) || (Local0 == 0x02)))
            {
                Local0 = \_SB.CLVL /* External reference */
            }
            Else
            {
                Return (Package (0x01)
                {
                    Zero
                })
            }

            If ((CLCK == One))
            {
                Local0 = One
            }

            AAAA = CPNU (\_SB.PL10, One)
            BBBB = CPNU (\_SB.PL11, One)
            CCCC = CPNU (\_SB.PL12, One)
            Name (TMP1, Package (0x01)
            {
                Package (0x05)
                {
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000
                }
            })
            Name (TMP2, Package (0x02)
            {
                Package (0x05)
                {
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000
                }, 

                Package (0x05)
                {
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000
                }
            })
            Name (TMP3, Package (0x03)
            {
                Package (0x05)
                {
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000
                }, 

                Package (0x05)
                {
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000
                }, 

                Package (0x05)
                {
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000
                }
            })
            If ((Local0 == 0x03))
            {
                If ((AAAA > BBBB))
                {
                    If ((AAAA > CCCC))
                    {
                        If ((BBBB > CCCC))
                        {
                            Local3 = Zero
                            LEV0 = Zero
                            Local4 = One
                            LEV1 = One
                            Local5 = 0x02
                            LEV2 = 0x02
                        }
                        Else
                        {
                            Local3 = Zero
                            LEV0 = Zero
                            Local5 = One
                            LEV1 = 0x02
                            Local4 = 0x02
                            LEV2 = One
                        }
                    }
                    Else
                    {
                        Local5 = Zero
                        LEV0 = 0x02
                        Local3 = One
                        LEV1 = Zero
                        Local4 = 0x02
                        LEV2 = One
                    }
                }
                ElseIf ((BBBB > CCCC))
                {
                    If ((AAAA > CCCC))
                    {
                        Local4 = Zero
                        LEV0 = One
                        Local3 = One
                        LEV1 = Zero
                        Local5 = 0x02
                        LEV2 = 0x02
                    }
                    Else
                    {
                        Local4 = Zero
                        LEV0 = One
                        Local5 = One
                        LEV1 = 0x02
                        Local3 = 0x02
                        LEV2 = Zero
                    }
                }
                Else
                {
                    Local5 = Zero
                    LEV0 = 0x02
                    Local4 = One
                    LEV1 = One
                    Local3 = 0x02
                    LEV2 = Zero
                }

                Local1 = (\_SB.TAR0 + One)
                Local2 = (Local1 * 0x64)
                DerefOf (TMP3 [Local3]) [Zero] = AAAA /* \_SB_.PC00.TCPU.TDPL.AAAA */
                DerefOf (TMP3 [Local3]) [One] = Local2
                DerefOf (TMP3 [Local3]) [0x02] = \_SB.CTC0 /* External reference */
                DerefOf (TMP3 [Local3]) [0x03] = Local1
                DerefOf (TMP3 [Local3]) [0x04] = Zero
                Local1 = (\_SB.TAR1 + One)
                Local2 = (Local1 * 0x64)
                DerefOf (TMP3 [Local4]) [Zero] = BBBB /* \_SB_.PC00.TCPU.TDPL.BBBB */
                DerefOf (TMP3 [Local4]) [One] = Local2
                DerefOf (TMP3 [Local4]) [0x02] = \_SB.CTC1 /* External reference */
                DerefOf (TMP3 [Local4]) [0x03] = Local1
                DerefOf (TMP3 [Local4]) [0x04] = Zero
                Local1 = (\_SB.TAR2 + One)
                Local2 = (Local1 * 0x64)
                DerefOf (TMP3 [Local5]) [Zero] = CCCC /* \_SB_.PC00.TCPU.TDPL.CCCC */
                DerefOf (TMP3 [Local5]) [One] = Local2
                DerefOf (TMP3 [Local5]) [0x02] = \_SB.CTC2 /* External reference */
                DerefOf (TMP3 [Local5]) [0x03] = Local1
                DerefOf (TMP3 [Local5]) [0x04] = Zero
                Return (TMP3) /* \_SB_.PC00.TCPU.TDPL.TMP3 */
            }

            If ((Local0 == 0x02))
            {
                If ((AAAA > BBBB))
                {
                    Local3 = Zero
                    Local4 = One
                    LEV0 = Zero
                    LEV1 = One
                    LEV2 = Zero
                }
                Else
                {
                    Local4 = Zero
                    Local3 = One
                    LEV0 = One
                    LEV1 = Zero
                    LEV2 = Zero
                }

                Local1 = (\_SB.TAR0 + One)
                Local2 = (Local1 * 0x64)
                DerefOf (TMP2 [Local3]) [Zero] = AAAA /* \_SB_.PC00.TCPU.TDPL.AAAA */
                DerefOf (TMP2 [Local3]) [One] = Local2
                DerefOf (TMP2 [Local3]) [0x02] = \_SB.CTC0 /* External reference */
                DerefOf (TMP2 [Local3]) [0x03] = Local1
                DerefOf (TMP2 [Local3]) [0x04] = Zero
                Local1 = (\_SB.TAR1 + One)
                Local2 = (Local1 * 0x64)
                DerefOf (TMP2 [Local4]) [Zero] = BBBB /* \_SB_.PC00.TCPU.TDPL.BBBB */
                DerefOf (TMP2 [Local4]) [One] = Local2
                DerefOf (TMP2 [Local4]) [0x02] = \_SB.CTC1 /* External reference */
                DerefOf (TMP2 [Local4]) [0x03] = Local1
                DerefOf (TMP2 [Local4]) [0x04] = Zero
                Return (TMP2) /* \_SB_.PC00.TCPU.TDPL.TMP2 */
            }

            If ((Local0 == One))
            {
                Switch (ToInteger (\_SB.CBMI))
                {
                    Case (Zero)
                    {
                        Local1 = (\_SB.TAR0 + One)
                        Local2 = (Local1 * 0x64)
                        DerefOf (TMP1 [Zero]) [Zero] = AAAA /* \_SB_.PC00.TCPU.TDPL.AAAA */
                        DerefOf (TMP1 [Zero]) [One] = Local2
                        DerefOf (TMP1 [Zero]) [0x02] = \_SB.CTC0 /* External reference */
                        DerefOf (TMP1 [Zero]) [0x03] = Local1
                        DerefOf (TMP1 [Zero]) [0x04] = Zero
                        LEV0 = Zero
                        LEV1 = Zero
                        LEV2 = Zero
                    }
                    Case (One)
                    {
                        Local1 = (\_SB.TAR1 + One)
                        Local2 = (Local1 * 0x64)
                        DerefOf (TMP1 [Zero]) [Zero] = BBBB /* \_SB_.PC00.TCPU.TDPL.BBBB */
                        DerefOf (TMP1 [Zero]) [One] = Local2
                        DerefOf (TMP1 [Zero]) [0x02] = \_SB.CTC1 /* External reference */
                        DerefOf (TMP1 [Zero]) [0x03] = Local1
                        DerefOf (TMP1 [Zero]) [0x04] = Zero
                        LEV0 = One
                        LEV1 = One
                        LEV2 = One
                    }
                    Case (0x02)
                    {
                        Local1 = (\_SB.TAR2 + One)
                        Local2 = (Local1 * 0x64)
                        DerefOf (TMP1 [Zero]) [Zero] = CCCC /* \_SB_.PC00.TCPU.TDPL.CCCC */
                        DerefOf (TMP1 [Zero]) [One] = Local2
                        DerefOf (TMP1 [Zero]) [0x02] = \_SB.CTC2 /* External reference */
                        DerefOf (TMP1 [Zero]) [0x03] = Local1
                        DerefOf (TMP1 [Zero]) [0x04] = Zero
                        LEV0 = 0x02
                        LEV1 = 0x02
                        LEV2 = 0x02
                    }

                }

                Return (TMP1) /* \_SB_.PC00.TCPU.TDPL.TMP1 */
            }

            Return (Zero)
        }

        Name (MAXT, Zero)
        Method (TDPC, 0, NotSerialized)
        {
            Return (MAXT) /* \_SB_.PC00.TCPU.MAXT */
        }

        Name (LEV0, Zero)
        Name (LEV1, Zero)
        Name (LEV2, Zero)
        Method (STDP, 1, Serialized)
        {
            If ((Arg0 >= \_SB.CLVL))
            {
                Return (Zero)
            }

            Switch (ToInteger (Arg0))
            {
                Case (Zero)
                {
                    Local0 = LEV0 /* \_SB_.PC00.TCPU.LEV0 */
                }
                Case (One)
                {
                    Local0 = LEV1 /* \_SB_.PC00.TCPU.LEV1 */
                }
                Case (0x02)
                {
                    Local0 = LEV2 /* \_SB_.PC00.TCPU.LEV2 */
                }

            }

            Switch (ToInteger (Local0))
            {
                Case (Zero)
                {
                    CPL0 ()
                }
                Case (One)
                {
                    CPL1 ()
                }
                Case (0x02)
                {
                    CPL2 ()
                }

            }

            Notify (\_SB.PC00.TCPU, 0x83) // Device-Specific Change
        }
    }

    Scope (\_SB.IETM)
    {
        Name (DP2P, Package (0x01)
        {
            ToUUID ("9e04115a-ae87-4d1c-9500-0f3e340bfe75") /* Unknown UUID */
        })
        Name (DPSP, Package (0x01)
        {
            ToUUID ("42a441d6-ae6a-462b-a84b-4a8ce79027d3") /* Unknown UUID */
        })
        Name (DASP, Package (0x01)
        {
            ToUUID ("3a95c389-e4b8-4629-a526-c52c88626bae") /* Unknown UUID */
        })
        Name (DA2P, Package (0x01)
        {
            ToUUID ("0e56fab6-bdfc-4e8c-8246-40ecfd4d74ea") /* Unknown UUID */
        })
        Name (DCSP, Package (0x01)
        {
            ToUUID ("97c68ae7-15fa-499c-b8c9-5da81d606e0a") /* Unknown UUID */
        })
        Name (RFIP, Package (0x01)
        {
            ToUUID ("c4ce1849-243a-49f3-b8d5-f97002f38e6a") /* Unknown UUID */
        })
        Name (POBP, Package (0x01)
        {
            ToUUID ("f5a35014-c209-46a4-993a-eb56de7530a1") /* Unknown UUID */
        })
        Name (DAPP, Package (0x01)
        {
            ToUUID ("63be270f-1c11-48fd-a6f7-3af253ff3e2d") /* Unknown UUID */
        })
        Name (DVSP, Package (0x01)
        {
            ToUUID ("6ed722a7-9240-48a5-b479-31eef723d7cf") /* Unknown UUID */
        })
        Name (DPID, Package (0x01)
        {
            ToUUID ("42496e14-bc1b-46e8-a798-ca915464426f") /* Unknown UUID */
        })
    }
}

