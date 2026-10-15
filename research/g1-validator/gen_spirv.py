#!/usr/bin/env python3
"""Emit the G1 validator's SPIR-V 1.0 shaders as g1_shaders.h, without any shader compiler.

The integer hash must match g1_ref.h exactly:
    v ^= v >> 16; v *= 0x7feb352d; v ^= v >> 15; v *= 0x846ca68b; v ^= v >> 16
    value(index, nonce) = hash(index * 0x9E3779B9 + nonce)

compute  (local_size 64): if (gid.x < pc.count) buf[gid.x] = value(gid.x, pc.nonce)
vertex:   full-screen triangle from VertexIndex: (-1,-1), (3,-1), (-1,3)
fragment: out uint = value(uint(FragCoord.y) * pc.width + uint(FragCoord.x), pc.nonce)  (R32_UINT attachment)
"""
import hashlib
import struct
import sys
from pathlib import Path

# opcodes
CAPABILITY, MEMORY_MODEL, ENTRY_POINT, EXECUTION_MODE = 17, 14, 15, 16
TYPE_VOID, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_VECTOR = 19, 20, 21, 22, 23
TYPE_RUNTIME_ARRAY, TYPE_STRUCT, TYPE_POINTER, TYPE_FUNCTION = 29, 30, 32, 33
CONSTANT, FUNCTION, FUNCTION_END, VARIABLE, LOAD, STORE, ACCESS_CHAIN = 43, 54, 56, 59, 61, 62, 65
DECORATE, MEMBER_DECORATE, COMPOSITE_CONSTRUCT, COMPOSITE_EXTRACT = 71, 72, 80, 81
CONVERT_F_TO_U, CONVERT_S_TO_F = 109, 111
I_ADD, F_SUB, I_MUL, F_MUL = 128, 131, 132, 133
U_LESS_THAN = 176
SHIFT_RIGHT_LOGICAL, SHIFT_LEFT_LOGICAL, BITWISE_XOR, BITWISE_AND = 194, 196, 198, 199
SELECTION_MERGE, LABEL, BRANCH, BRANCH_CONDITIONAL, RETURN = 247, 248, 249, 250, 253

# enums
SC_INPUT, SC_UNIFORM, SC_OUTPUT, SC_PUSH_CONSTANT = 1, 2, 3, 9
DEC_BLOCK, DEC_BUFFER_BLOCK, DEC_ARRAY_STRIDE, DEC_BUILTIN = 2, 3, 6, 11
DEC_LOCATION, DEC_BINDING, DEC_DESCRIPTOR_SET, DEC_OFFSET = 30, 33, 34, 35
BI_POSITION, BI_FRAG_COORD, BI_GLOBAL_INVOCATION_ID, BI_VERTEX_INDEX = 0, 15, 28, 42
EM_VERTEX, EM_FRAGMENT, EM_GLCOMPUTE = 0, 4, 5
EXEC_ORIGIN_UPPER_LEFT, EXEC_LOCAL_SIZE = 7, 17


def words_of_string(s):
    b = s.encode() + b"\0"
    b += b"\0" * (-len(b) % 4)
    return list(struct.unpack(f"<{len(b) // 4}I", b))


def inst(op, *operands):
    w = []
    for o in operands:
        w += words_of_string(o) if isinstance(o, str) else [o]
    return [(len(w) + 1) << 16 | op] + w


class Module:
    def __init__(self):
        self.bound = 1
        self.head, self.decor, self.glob, self.body = [], [], [], []
        self.cache = {}

    def new(self):
        self.bound += 1
        return self.bound - 1

    def _global(self, key, build):
        if key not in self.cache:
            self.cache[key] = build()
        return self.cache[key]

    def type(self, op, *args):
        def build():
            i = self.new()
            self.glob += inst(op, i, *args)
            return i
        return self._global(("t", op) + args, build)

    def const(self, ty, value):
        def build():
            i = self.new()
            self.glob += inst(CONSTANT, ty, i, value)
            return i
        return self._global(("c", ty, value), build)

    def struct(self, *members):
        i = self.new()
        self.glob += inst(TYPE_STRUCT, i, *members)
        return i

    def var(self, ptr_type, sc):
        i = self.new()
        self.glob += inst(VARIABLE, ptr_type, i, sc)
        return i

    def dec(self, target, *args):
        self.decor += inst(DECORATE, target, *args)

    def mdec(self, target, member, *args):
        self.decor += inst(MEMBER_DECORATE, target, member, *args)

    def op(self, opcode, ty, *args):
        i = self.new()
        self.body += inst(opcode, ty, i, *args)
        return i

    def raw(self, opcode, *args):
        self.body += inst(opcode, *args)

    def label(self, i=None):
        i = i or self.new()
        self.body += inst(LABEL, i)
        return i

    # common types
    def void(self): return self.type(TYPE_VOID)
    def uint(self): return self.type(TYPE_INT, 32, 0)
    def int(self): return self.type(TYPE_INT, 32, 1)
    def float(self): return self.type(TYPE_FLOAT, 32)
    def ptr(self, sc, ty): return self.type(TYPE_POINTER, sc, ty)
    def u(self, v): return self.const(self.uint(), v)
    def i(self, v): return self.const(self.int(), v)
    def f(self, v): return self.const(self.float(), struct.unpack("<I", struct.pack("<f", v))[0])

    def begin_main(self):
        main, fn_type = self.new(), self.type(TYPE_FUNCTION, self.void())
        self.body += inst(FUNCTION, self.void(), main, 0, fn_type)
        self.label()
        return main

    def end_main(self):
        self.raw(RETURN)
        self.raw(FUNCTION_END)

    def hash_value(self, index, nonce):
        u = self.uint()
        v = self.op(I_ADD, u, self.op(I_MUL, u, index, self.u(0x9E3779B9)), nonce)
        v = self.op(BITWISE_XOR, u, v, self.op(SHIFT_RIGHT_LOGICAL, u, v, self.u(16)))
        v = self.op(I_MUL, u, v, self.u(0x7FEB352D))
        v = self.op(BITWISE_XOR, u, v, self.op(SHIFT_RIGHT_LOGICAL, u, v, self.u(15)))
        v = self.op(I_MUL, u, v, self.u(0x846CA68B))
        return self.op(BITWISE_XOR, u, v, self.op(SHIFT_RIGHT_LOGICAL, u, v, self.u(16)))

    def push_constants_2u(self):
        pc_t = self.struct(self.uint(), self.uint())
        self.dec(pc_t, DEC_BLOCK)
        self.mdec(pc_t, 0, DEC_OFFSET, 0)
        self.mdec(pc_t, 1, DEC_OFFSET, 4)
        return self.var(self.ptr(SC_PUSH_CONSTANT, pc_t), SC_PUSH_CONSTANT)

    def load_pc(self, pc, member):
        p = self.op(ACCESS_CHAIN, self.ptr(SC_PUSH_CONSTANT, self.uint()), pc, self.i(member))
        return self.op(LOAD, self.uint(), p)

    def binary(self, model, main, interface, modes):
        head = inst(CAPABILITY, 1) + inst(MEMORY_MODEL, 0, 1) + inst(ENTRY_POINT, model, main, "main", *interface)
        for m in modes:
            head += inst(EXECUTION_MODE, main, *m)
        w = [0x07230203, 0x00010000, 0, self.bound, 0] + head + self.decor + self.glob + self.body
        return struct.pack(f"<{len(w)}I", *w)


def compute():
    m = Module()
    u = m.uint()
    gid = m.var(m.ptr(SC_INPUT, m.type(TYPE_VECTOR, u, 3)), SC_INPUT)
    m.dec(gid, DEC_BUILTIN, BI_GLOBAL_INVOCATION_ID)
    arr = m.type(TYPE_RUNTIME_ARRAY, u)
    m.dec(arr, DEC_ARRAY_STRIDE, 4)
    buf_t = m.struct(arr)
    m.dec(buf_t, DEC_BUFFER_BLOCK)
    m.mdec(buf_t, 0, DEC_OFFSET, 0)
    buf = m.var(m.ptr(SC_UNIFORM, buf_t), SC_UNIFORM)
    m.dec(buf, DEC_DESCRIPTOR_SET, 0)
    m.dec(buf, DEC_BINDING, 0)
    pc = m.push_constants_2u()
    bool_t, ptr_elem = m.type(TYPE_BOOL), m.ptr(SC_UNIFORM, u)

    main = m.begin_main()
    idx = m.op(COMPOSITE_EXTRACT, u, m.op(LOAD, m.type(TYPE_VECTOR, u, 3), gid), 0)
    nonce, count = m.load_pc(pc, 0), m.load_pc(pc, 1)
    cond = m.op(U_LESS_THAN, bool_t, idx, count)
    then_l, merge_l = m.new(), m.new()
    m.raw(SELECTION_MERGE, merge_l, 0)
    m.raw(BRANCH_CONDITIONAL, cond, then_l, merge_l)
    m.label(then_l)
    val = m.hash_value(idx, nonce)
    m.raw(STORE, m.op(ACCESS_CHAIN, ptr_elem, buf, m.i(0), idx), val)
    m.raw(BRANCH, merge_l)
    m.label(merge_l)
    m.end_main()
    return m.binary(EM_GLCOMPUTE, main, [gid], [(EXEC_LOCAL_SIZE, 64, 1, 1)])


def vertex():
    m = Module()
    i32, f32 = m.int(), m.float()
    vec4 = m.type(TYPE_VECTOR, f32, 4)
    vi = m.var(m.ptr(SC_INPUT, i32), SC_INPUT)
    m.dec(vi, DEC_BUILTIN, BI_VERTEX_INDEX)
    pos = m.var(m.ptr(SC_OUTPUT, vec4), SC_OUTPUT)
    m.dec(pos, DEC_BUILTIN, BI_POSITION)

    main = m.begin_main()
    i = m.op(LOAD, i32, vi)
    xi = m.op(BITWISE_AND, i32, m.op(SHIFT_LEFT_LOGICAL, i32, i, m.i(1)), m.i(2))
    yi = m.op(BITWISE_AND, i32, i, m.i(2))
    x = m.op(F_SUB, f32, m.op(F_MUL, f32, m.op(CONVERT_S_TO_F, f32, xi), m.f(2.0)), m.f(1.0))
    y = m.op(F_SUB, f32, m.op(F_MUL, f32, m.op(CONVERT_S_TO_F, f32, yi), m.f(2.0)), m.f(1.0))
    m.raw(STORE, pos, m.op(COMPOSITE_CONSTRUCT, vec4, x, y, m.f(0.0), m.f(1.0)))
    m.end_main()
    return m.binary(EM_VERTEX, main, [vi, pos], [])


def fragment():
    m = Module()
    u, f32 = m.uint(), m.float()
    vec4 = m.type(TYPE_VECTOR, f32, 4)
    fc = m.var(m.ptr(SC_INPUT, vec4), SC_INPUT)
    m.dec(fc, DEC_BUILTIN, BI_FRAG_COORD)
    out = m.var(m.ptr(SC_OUTPUT, u), SC_OUTPUT)
    m.dec(out, DEC_LOCATION, 0)
    pc = m.push_constants_2u()

    main = m.begin_main()
    c = m.op(LOAD, vec4, fc)
    x = m.op(CONVERT_F_TO_U, u, m.op(COMPOSITE_EXTRACT, f32, c, 0))
    y = m.op(CONVERT_F_TO_U, u, m.op(COMPOSITE_EXTRACT, f32, c, 1))
    nonce, width = m.load_pc(pc, 0), m.load_pc(pc, 1)
    m.raw(STORE, out, m.hash_value(m.op(I_ADD, u, m.op(I_MUL, u, y, width), x), nonce))
    m.end_main()
    return m.binary(EM_FRAGMENT, main, [fc, out], [(EXEC_ORIGIN_UPPER_LEFT,)])


def header():
    out = ["/* Generated by gen_spirv.py - do not edit. SPIR-V 1.0, little-endian words. */",
           "#ifndef G1_SHADERS_H", "#define G1_SHADERS_H", "#include <stdint.h>", ""]
    for name, blob in (("g1_comp", compute()), ("g1_vert", vertex()), ("g1_frag", fragment())):
        w = struct.unpack(f"<{len(blob) // 4}I", blob)
        out.append(f"/* {name}: {len(blob)} bytes, sha256 {hashlib.sha256(blob).hexdigest()} */")
        out.append(f"static const uint32_t {name}_spv[{len(w)}] = {{")
        for k in range(0, len(w), 8):
            out.append("    " + ", ".join(f"0x{x:08x}" for x in w[k:k + 8]) + ",")
        out.append("};")
        out.append("")
    out.append("#endif")
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    dest = Path(__file__).with_name("g1_shaders.h")
    text = header()
    if "--check" in sys.argv:
        sys.exit(0 if dest.read_text(encoding="utf-8") == text else 1)
    dest.write_text(text, encoding="utf-8", newline="\n")
    print(f"wrote {dest}")
