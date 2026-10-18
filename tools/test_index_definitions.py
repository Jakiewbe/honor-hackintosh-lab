"""Regression contracts for previously observed false source claims."""
import importlib.util
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('definition_index', Path(__file__).with_name('index-definitions.py'))
index = importlib.util.module_from_spec(spec)
spec.loader.exec_module(index)


class DefinitionIndexTests(unittest.TestCase):
    def test_real_multiline_return_types(self):
        text = 'NvS32\nRmInitRm(void)\n{ return coreInitializeRm() == NV_OK; }\n'
        self.assertEqual([h['name'] for h in index.function_candidates(text, {'RmInitRm'})], ['RmInitRm'])
        text = 'POBJGPU\ngpumgrGetGpuFromUuid(const NvU8 *id, NvU32 flags)\n{ return NULL; }'
        self.assertEqual(len(index.function_candidates(text, {'gpumgrGetGpuFromUuid'})), 1)

    def test_real_multiline_arguments(self):
        text = 'NV_STATUS\nRmPowerManagementTegra(\n OBJGPU *pGpu,\n nv_pm_action_t action\n)\n{ return 0; }'
        self.assertEqual(len(index.function_candidates(text, {'RmPowerManagementTegra'})), 1)

    def test_return_call_is_never_definition(self):
        text = 'NvU32 wrapper(NvU16 a) {\n return f16_to_f32(a).v;\n}'
        self.assertEqual(index.function_candidates(text, {'f16_to_f32'}), [])

    def test_declarations_comments_strings_and_macros_rejected(self):
        text = 'extern int target(void);\n// int target(void) {}\nchar *s="int target(void) {}";\n#define target(x) { x; }\n'
        self.assertEqual(index.function_candidates(text, {'target'}), [])

    def test_control_statement_and_nested_call_rejected(self):
        text = 'void wrapper(void) {\n if (target()) { target(); }\n target()\n { wrong(); }\n}'
        self.assertEqual(index.function_candidates(text, {'target'}), [])

    def test_all_conditional_definitions_retained(self):
        text = '#if A\nint target(void) { return 1; }\n#else\nint target(void) { return 2; }\n#endif'
        self.assertEqual(len(index.function_candidates(text, {'target'})), 2)

    def test_static_header_is_not_compilable_provider(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            (root/'inline.h').write_text('static inline int target(void) { return 1; }')
            report = index.build_index(root, {'target', 'unknown'})
            self.assertEqual(report['defining_files'], [])
            self.assertEqual(report['missing'], ['unknown'])
            self.assertEqual(report['unresolved_status'], 'UNKNOWN')
            self.assertIn('target', report['occurrences'])

    def test_unbalanced_syntax_never_provider(self):
        self.assertEqual(index.function_candidates('int target(void) { return 0;', {'target'}), [])


if __name__ == '__main__':
    unittest.main()
