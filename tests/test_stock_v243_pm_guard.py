"""Reject false baseline failures; CPU fixture observations must be exact."""
import importlib
from pathlib import Path
import sys
import unittest

sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts/g1'))
g=importlib.import_module('stock_v243_pm_guard')


class GuardContracts(unittest.TestCase):
    def observation(self,role):
        lines=[]
        for busy in (0,1,2,17):
            result='FAIL' if role=='baseline' and busy else 'PASS'
            lines += [f'busy={busy} ordered-effects={result}',f'busy={busy} state-and-marker={result}']
        total=2 if role=='baseline' else 8
        return '\n'.join(lines+[f'{total}/8 CPU call contracts; no device; no sleep-veto proof'])

    def test_exact_observations(self):
        g.accept_cpu('baseline',1,self.observation('baseline'))
        g.accept_cpu('candidate',0,self.observation('candidate'))

    def test_unrelated_failure_is_not_a_baseline_counterexample(self):
        for text in ('', '8/8 passed', 'AddressSanitizer: error',self.observation('baseline')+'\nSanitizer error'):
            with self.assertRaises(ValueError):g.accept_cpu('baseline',1,text)

    def test_exit_and_missing_scenarios_rejected(self):
        for role,rc in [('candidate',1),('baseline',0)]:
            with self.assertRaises(ValueError):g.accept_cpu(role,rc,self.observation(role))
        with self.assertRaises(ValueError):g.accept_cpu('candidate',0,self.observation('candidate').replace('busy=17','busy=18'))


if __name__=='__main__':unittest.main()
