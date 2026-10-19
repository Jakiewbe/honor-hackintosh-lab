"""Identity rejection against real R33 metadata; no driver/runtime claims."""
import copy
import json
from pathlib import Path
import tempfile
import unittest
from g1_verify_r33_native import verify

ROOT=Path(__file__).resolve().parents[1]
ART=ROOT/'evidence/ci-full-39189188122'


@unittest.skipUnless(ART.is_dir(), 'requires locally verified original R33 text artifact')
class RealIdentityControls(unittest.TestCase):
    def test_wrong_run_source_status_rejected(self):
        good=json.loads((ROOT/'evidence/r33-run-final-meta.json').read_text())
        for key,value in [('id',39186519502),('head_sha','0'*40),
                          ('status','queued'),('conclusion','failure')]:
            bad=copy.deepcopy(good);bad[key]=value
            with self.subTest(key=key), tempfile.TemporaryDirectory() as tmp:
                meta=Path(tmp)/'meta.json';meta.write_text(json.dumps(bad))
                with self.assertRaisesRegex(ValueError,'run/source/status mismatch'):
                    verify(ART,meta,Path(tmp)/'unused-baseline')

    def test_artifact_substitution_and_receipt_truncation_rejected(self):
        good=json.loads((ART/'local-artifact-binding.json').read_text())
        for key,value,error in [('artifact_id',12158179549,'external artifact identity'),
                                ('artifact_sha256','0'*64,'external artifact identity'),
                                ('members',[],'fixed verified ZIP receipt')]:
            bad=copy.deepcopy(good);bad[key]=value
            with self.subTest(key=key), tempfile.TemporaryDirectory() as tmp:
                root=Path(tmp)
                (root/'local-artifact-binding.json').write_text(json.dumps(bad))
                with self.assertRaisesRegex(ValueError,error):
                    verify(root,ROOT/'evidence/r33-run-final-meta.json',root/'unused-baseline')


if __name__=='__main__': unittest.main()
