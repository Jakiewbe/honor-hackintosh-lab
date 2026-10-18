#!/usr/bin/env python3
"""Regression cases for prior call/declaration/definition misclassification."""
import unittest
from pathlib import Path
from g1_dependency_audit import definitions
from g1_probe_inventory import derive_preprocess


class DefinitionTests(unittest.TestCase):
    def test_declarations_and_guarded_calls_are_not_definitions(self):
        text = '''NvBool rm_init_rm(nvidia_stack_t *);
if (!rm_init_rm(*sp)) { fail(); }
return rm_init_rm(sp);
'''
        self.assertEqual(definitions(text, {"rm_init_rm"}), [])

    def test_multiline_and_long_parameters(self):
        text = "NV_STATUS NV_API_CALL rm_ioctl\n(\n" + " " * 700 + "nvidia_stack_t *sp)\n{\ncore(sp);\n}\n"
        result = definitions(text, {"rm_ioctl"})
        self.assertEqual(len(result), 1)
        self.assertEqual(result[0]["call_like_occurrences"], [{"name": "core", "line": 5}])

    def test_comments_strings_and_nested_braces(self):
        text = '''// int fake() { unsafe(); }
int real(void) {
  const char *s = "} fake() { unsafe();";
  /* fake() { unsafe(); } */
  if (nested(1, other(2))) { actual(); }
}
'''
        result = definitions(text, {"real", "fake"})
        self.assertEqual([r["name"] for r in result], ["real"])
        self.assertEqual([r["name"] for r in result[0]["call_like_occurrences"]], ["nested", "other", "actual"])

    def test_all_conditional_definitions_retained(self):
        text = "#if PLATFORM\nint f(void) { one(); }\n#else\nint f(void) { two(); }\n#endif\n"
        self.assertEqual(len(definitions(text, {"f"})), 2)

    def test_macro_body_is_not_c_definition(self):
        text = "#define X \\\n+int f(void) { hidden(); }\nint g(void) { visible(); }\n"
        self.assertEqual([r["name"] for r in definitions(text, {"f", "g"})], ["g"])

    def test_preprocess_keeps_flags_and_never_writes_object(self):
        base, obj = derive_preprocess(["xcrun", "clang", "-x", "c", "-DNVRM", "-c", "osapi.c", "-o", "probe.o"], Path("osapi.c"))
        self.assertEqual(base, ["xcrun", "clang", "-x", "c", "-DNVRM"])
        self.assertEqual(obj, Path("probe.o"))

    def test_preprocess_refuses_wrong_source(self):
        with self.assertRaises(ValueError):
            derive_preprocess(["xcrun", "clang", "-c", "wrong.c", "-o", "probe.o"], Path("osapi.c"))


if __name__ == "__main__":
    unittest.main()
