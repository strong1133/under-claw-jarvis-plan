import copy
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('evidence', ROOT / 'shared/evidence.py')
evidence = importlib.util.module_from_spec(spec)
spec.loader.exec_module(evidence)


class EvidenceTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.contract = {'schema_version': 1, 'goal': 'Produce a report', 'scope': ['output.txt'],
                         'constraints': [], 'blocking_questions': [], 'criteria': [
                             {'id': 'C1', 'description': 'Preserve amounts', 'required': True,
                              'verification': 'Compare with source', 'stage': 'implement'}]}
        self.cp = self.root / 'contract.json'
        self.cp.write_text(json.dumps(self.contract))
        (self.root / 'output.txt').write_text('Amount: 100')
        (self.root / 'check.txt').write_text('Compared source and output: 100 == 100')
        self.report = {'schema_version': 1, 'contract_sha256': evidence.digest(self.cp),
                       'review_mode': 'independent', 'blockers': [], 'artifacts': [
                           {'path': n, 'sha256': evidence.digest(self.root / n), 'kind': k}
                           for n, k in [('output.txt', 'deliverable'), ('check.txt', 'evidence')]],
                       'results': [{'id': 'C1', 'status': 'pass', 'evidence': ['check.txt'],
                                    'note': 'Amount preserved', 'stage': 'implement'}],
                       'scores': {'D1': 4, 'D2': 3, 'D3': 2, 'D4': 0.5}}
        self.rp = self.root / 'report.json'

    def judge(self, target='9.5'):
        self.rp.write_text(json.dumps(self.report))
        return evidence.judge(self.cp, self.rp, self.root, target)

    def test_exact_target_passes(self):
        self.assertTrue(self.judge()['passed'])

    def test_score_cannot_hide_missing_required_result(self):
        self.report['scores']['D4'] = 1
        self.report['results'] = []
        result = self.judge()
        self.assertFalse(result['passed'])
        self.assertFalse(result['hard_pass'])

    def test_unknown_or_failed_required_criterion_routes_to_cause(self):
        for status, stage in [('fail', 'plan'), ('unknown', 'understand')]:
            with self.subTest(status=status):
                self.report['results'][0].update(status=status, stage=stage)
                result = self.judge()
                self.assertFalse(result['passed'])
                self.assertEqual(result['resume_stage'], stage)

    def test_missing_log_with_low_score_rechecks_evidence_before_rework(self):
        (self.root / 'check.txt').unlink()
        self.report['scores']['D4'] = 0.1
        result = self.judge()
        self.assertFalse(result['passed'])
        self.assertEqual(result['resume_stage'], 'review')

    def test_missing_evidence_reference_routes_to_review(self):
        self.report['results'][0]['evidence'] = []
        self.report['scores']['D4'] = 0.1
        self.assertEqual(self.judge()['resume_stage'], 'review')

    def test_missing_evidence_rejected_even_at_ten(self):
        self.report['scores']['D4'] = 1
        self.report['results'][0]['evidence'] = []
        self.assertFalse(self.judge()['hard_pass'])

    def test_changed_deliverable_invalidates_previous_pass(self):
        (self.root / 'output.txt').write_text('Amount: 999')
        self.assertFalse(self.judge()['passed'])

    def test_missing_log_invalidates_pass(self):
        (self.root / 'check.txt').unlink()
        self.assertFalse(self.judge()['passed'])

    def test_changed_contract_invalidates_previous_pass(self):
        self.contract['goal'] = 'Different goal'
        self.cp.write_text(json.dumps(self.contract))
        self.assertFalse(self.judge()['passed'])

    def test_no_rounding_up(self):
        self.report['scores']['D4'] = 0.49
        result = self.judge()
        self.assertTrue(result['hard_pass'])
        self.assertFalse(result['passed'])

    def test_blocker_is_hard_failure(self):
        self.report['blockers'] = ['Incorrect customer name']
        self.assertFalse(self.judge()['passed'])

    def test_blocking_question_prevents_execution_verdict(self):
        self.contract['blocking_questions'] = ['Which customer?']
        self.cp.write_text(json.dumps(self.contract))
        self.report['contract_sha256'] = evidence.digest(self.cp)
        self.assertEqual(self.judge()['resume_stage'], 'understand')

    def test_optional_failure_is_recorded_but_not_required(self):
        criterion = copy.deepcopy(self.contract['criteria'][0])
        criterion.update(id='C2', required=False)
        self.contract['criteria'].append(criterion)
        self.cp.write_text(json.dumps(self.contract))
        self.report['contract_sha256'] = evidence.digest(self.cp)
        self.report['results'].append(dict(id='C2', status='fail', evidence=[], note='Optional polish omitted', stage='implement'))
        self.assertTrue(self.judge()['passed'])

    def test_escapes_and_symlink_escapes_rejected(self):
        for path in ['/etc/passwd', '../other.txt']:
            with self.subTest(path=path):
                self.report['artifacts'][0]['path'] = path
                with self.assertRaises(ValueError): self.judge()
        (self.root / 'outside').symlink_to(self.root.parent)
        self.report['artifacts'][0]['path'] = 'outside/other.txt'
        with self.assertRaises(ValueError): self.judge()

    def test_invalid_numbers_rejected(self):
        for value in [float('nan'), float('inf'), -1, 11, True]:
            with self.subTest(value=value):
                with self.assertRaises(ValueError): self.judge(value)
        for value in [float('nan'), 2, True]:
            with self.subTest(score=value):
                self.report['scores']['D4'] = value
                with self.assertRaises(ValueError): self.judge()

    def test_duplicate_criteria_and_results_rejected(self):
        self.report['results'].append(copy.deepcopy(self.report['results'][0]))
        with self.assertRaises(ValueError): self.judge()
        self.contract['criteria'].append(copy.deepcopy(self.contract['criteria'][0]))
        with self.assertRaises(ValueError): evidence.validate_contract(self.contract)

    def test_degraded_review_is_explicit(self):
        self.report['review_mode'] = 'degraded'
        result = self.judge()
        self.assertTrue(result['passed'])
        self.assertEqual(result['review_mode'], 'degraded')

    def test_plan_does_not_require_quality_score(self):
        del self.report['scores']
        self.assertTrue(self.judge(None)['passed'])
        self.assertFalse(self.judge()['passed'])

    def test_cli_bad_json_and_failure_exit_codes(self):
        self.rp.write_text('{"schema_version":1,"schema_version":1}')
        proc = subprocess.run(['python3', str(ROOT/'shared/evidence.py'), 'judge', str(self.cp), str(self.rp), '--root', str(self.root)], capture_output=True, text=True)
        self.assertEqual(proc.returncode, 2)
        self.report['results'][0]['status'] = 'unknown'
        self.rp.write_text(json.dumps(self.report))
        proc = subprocess.run(['python3', str(ROOT/'shared/evidence.py'), 'judge', str(self.cp), str(self.rp), '--root', str(self.root)], capture_output=True, text=True)
        self.assertEqual(proc.returncode, 1)
        self.assertFalse(json.loads(proc.stdout)['passed'])

    def test_spec_save_and_invalid_update_preserve_existing(self):
        save = ROOT / 'skills/under-claw-meta-prompt/scripts/save-prompt.sh'
        directory = self.root/'prompts'
        directory.mkdir()
        (directory/'PROMPT.md').write_text('existing prompt')
        proc = subprocess.run(['bash', str(save), '--spec', str(directory)], input=json.dumps(self.contract), capture_output=True, text=True)
        self.assertEqual(proc.returncode, 0, proc.stderr)
        target = directory/'CONTRACT.json'
        self.assertEqual(json.loads(target.read_text()), self.contract)
        original = target.read_bytes()
        proc = subprocess.run(['bash', str(save), '--spec', str(target)], input='{}', capture_output=True, text=True)
        self.assertEqual(proc.returncode, 2)
        self.assertEqual(target.read_bytes(), original)
        self.assertEqual((directory/'PROMPT.md').read_text(), 'existing prompt')
        fresh = self.root/'new.json'
        proc = subprocess.run(['bash', str(save), '--spec', str(fresh)], input=json.dumps(self.contract), capture_output=True, text=True)
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertTrue(fresh.is_file())


if __name__ == '__main__':
    unittest.main()
