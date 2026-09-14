#!/usr/bin/env python3
"""Validate recorded evidence and gates. Does not execute or authenticate checks."""
import argparse
from decimal import Decimal, InvalidOperation
import hashlib
import json
from pathlib import Path
import re
import sys

STAGES = ('understand', 'plan', 'implement', 'review')
MAX_SCORES = {'D1': 4, 'D2': 3, 'D3': 2, 'D4': 1}


def require(condition, message):
    if not condition:
        raise ValueError(message)


def nonempty(value):
    return isinstance(value, str) and bool(value.strip())


def strings(value):
    return isinstance(value, list) and all(nonempty(item) for item in value)


def number(value, maximum):
    require(not isinstance(value, bool) and isinstance(value, (int, float, str, Decimal)), 'invalid number')
    try:
        result = Decimal(str(value))
    except InvalidOperation as exc:
        raise ValueError('invalid number') from exc
    require(result.is_finite() and 0 <= result <= maximum, 'number out of range')
    return result


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, 'duplicate JSON key: ' + key)
        result[key] = value
    return result


def read_json(path):
    result = json.loads(path.read_text(), object_pairs_hook=unique_object)
    require(isinstance(result, dict), 'expected JSON object')
    return result


def validate_contract(contract):
    require(type(contract.get('schema_version')) is int and contract['schema_version'] == 1, 'unsupported contract schema')
    require(nonempty(contract.get('goal')), 'goal required')
    for key in ('scope', 'constraints', 'blocking_questions'):
        require(strings(contract.get(key)), key + ' must be a string array')
    require(contract['scope'], 'scope required')
    criteria = contract.get('criteria')
    require(isinstance(criteria, list) and criteria, 'criteria required')
    ids = set()
    for criterion in criteria:
        require(isinstance(criterion, dict), 'invalid criterion')
        cid = criterion.get('id')
        require(nonempty(cid) and cid not in ids, 'missing or duplicate criterion id')
        ids.add(cid)
        require(nonempty(criterion.get('description')), 'criterion description required')
        require(type(criterion.get('required')) is bool, 'required must be boolean')
        require(nonempty(criterion.get('verification')), 'verification method required')
        require(criterion.get('stage') in STAGES, 'invalid criterion stage')
    require(any(c['required'] for c in criteria), 'at least one required criterion needed')
    return criteria


def judge(contract_path, report_path, root, target=None):
    contract = read_json(contract_path)
    criteria = validate_contract(contract)
    report = read_json(report_path)
    require(type(report.get('schema_version')) is int and report['schema_version'] == 1, 'unsupported report schema')
    require(report.get('review_mode') in ('independent', 'degraded'), 'review mode required')
    require(strings(report.get('blockers')), 'blockers must be a string array')
    require(root.is_dir(), 'artifact root must be a directory')
    root = root.resolve()
    issues, stages = [], []

    def fail(message, stage='review'):
        issues.append(message)
        stages.append(stage)

    if contract['blocking_questions']:
        fail('unresolved blocking questions', 'understand')
    if report.get('contract_sha256') != digest(contract_path):
        fail('contract hash mismatch', 'understand')
    if report['blockers']:
        fail('unresolved blockers: ' + '; '.join(report['blockers']))
    artifacts = report.get('artifacts')
    require(isinstance(artifacts, list) and artifacts, 'artifacts required')
    files, deliverables = {}, 0
    for artifact in artifacts:
        require(isinstance(artifact, dict), 'invalid artifact')
        name = artifact.get('path')
        require(nonempty(name) and name not in files, 'missing or duplicate artifact path')
        require(artifact.get('kind') in ('deliverable', 'evidence'), 'invalid artifact kind')
        require(isinstance(artifact.get('sha256'), str) and re.fullmatch('[0-9a-f]{64}', artifact['sha256']), 'invalid artifact hash')
        path = Path(name)
        require(not path.is_absolute() and '..' not in path.parts, 'artifact path must stay inside root')
        resolved = (root / path).resolve()
        require(root in resolved.parents, 'artifact path escapes root')
        files[name] = artifact['kind']
        deliverables += artifact['kind'] == 'deliverable'
        if not resolved.is_file() or digest(resolved) != artifact['sha256']:
            fail('missing or changed artifact: ' + name)
    require(deliverables > 0, 'deliverable artifact required')
    results = report.get('results')
    require(isinstance(results, list), 'results required')
    by_id = {}
    ids = {c['id'] for c in criteria}
    for result in results:
        require(isinstance(result, dict), 'invalid result')
        cid = result.get('id')
        require(isinstance(cid, str) and cid in ids and cid not in by_id, 'unknown or duplicate result id')
        require(result.get('status') in ('pass', 'fail', 'unknown'), 'invalid result status')
        require(strings(result.get('evidence')), 'evidence must be a string array')
        require(nonempty(result.get('note')), 'result note required')
        require(result.get('stage') in STAGES, 'invalid result stage')
        require(all(files.get(p) == 'evidence' for p in result['evidence']), 'evidence reference must name an evidence artifact')
        by_id[cid] = result
    for criterion in criteria:
        cid = criterion['id']
        result = by_id.get(cid)
        if result is None:
            fail('missing result: ' + cid)
        elif criterion['required'] and result['status'] != 'pass':
            fail('required criterion not evidenced: ' + cid, result['stage'])
        elif criterion['required'] and not result['evidence']:
            fail('required criterion missing evidence: ' + cid)
    hard_pass = not issues
    score = None
    if 'scores' in report:
        require(isinstance(report['scores'], dict) and set(report['scores']) == set(MAX_SCORES), 'D1-D4 scores required')
        score = sum(number(report['scores'][key], limit) for key, limit in MAX_SCORES.items())
    if target is not None:
        target = number(target, 10)
        if score is None or score < target:
            if hard_pass:
                fail('quality target not met', 'implement')
            else:
                issues.append('quality target not met')
    return {'passed': not issues, 'hard_pass': hard_pass, 'score': float(score) if score is not None else None,
            'review_mode': report['review_mode'],
            'resume_stage': min(stages, key=STAGES.index) if stages else None, 'issues': issues}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest='command', required=True)
    contract = sub.add_parser('contract')
    contract.add_argument('path', type=Path)
    review = sub.add_parser('judge')
    review.add_argument('contract', type=Path)
    review.add_argument('report', type=Path)
    review.add_argument('--root', required=True, type=Path)
    review.add_argument('--target')
    args = parser.parse_args()
    try:
        if args.command == 'contract':
            validate_contract(read_json(args.path))
            result = {'valid': True, 'contract_sha256': digest(args.path)}
        else:
            result = judge(args.contract, args.report, args.root, args.target)
    except (ValueError, OSError, TypeError) as exc:
        print(json.dumps({'error': str(exc)}, ensure_ascii=False))
        return 2
    print(json.dumps(result, ensure_ascii=False))
    return 0 if result.get('passed', True) else 1


if __name__ == '__main__':
    sys.exit(main())
