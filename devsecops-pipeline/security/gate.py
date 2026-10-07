"""Security gate: read every scanner report, apply security/policy.toml, decide.

    python security/gate.py <reports-dir> [--summary FILE]

Exit code 0 = every control within policy, 1 = at least one control blocks.
A missing or unreadable report blocks too (fail closed).
"""

import argparse
import json
import sys
import tomllib
from pathlib import Path

POLICY = Path(__file__).with_name("policy.toml")
RANK = {"UNKNOWN": 0, "LOW": 1, "MEDIUM": 2, "HIGH": 3, "CRITICAL": 4}


def load(path):
    with open(path) as fh:
        return json.load(fh)


def sast(reports, policy):
    data = load(reports / "bandit.json")
    min_conf = RANK[policy["min_confidence"]]
    findings, blocking = data.get("results", []), []
    for r in findings:
        if (
            r["issue_severity"] in policy["block_severity"]
            and RANK[r["issue_confidence"]] >= min_conf
        ):
            blocking.append(
                f"{r['test_id']} {r['issue_severity']}/{r['issue_confidence']} "
                f"{r['filename']}:{r['line_number']} {r['issue_text']}"
            )
    rule = (
        f"severity {'/'.join(policy['block_severity'])}, confidence >= {policy['min_confidence']}"
    )
    return "SAST", "bandit", len(findings), blocking, rule


def sca(reports, policy):
    data = load(reports / "pip-audit.json")
    found = [
        f"{d['name']}=={d['version']} {v['id']} ({', '.join(v.get('aliases', [])) or '-'}) "
        f"fix: {', '.join(v.get('fix_versions', [])) or 'none'}"
        for d in data.get("dependencies", [])
        for v in d.get("vulns", [])
    ]
    blocking = found if len(found) > policy["max_vulnerabilities"] else []
    return (
        "SCA",
        "pip-audit",
        len(found),
        blocking,
        f"max {policy['max_vulnerabilities']} known vulns",
    )


def secrets(reports, policy):
    data = load(reports / "gitleaks.json") or []
    found = [f"{f['RuleID']} {f['File']}:{f['StartLine']} secret={f['Secret']}" for f in data]
    blocking = found if len(found) > policy["max_findings"] else []
    return "Secrets", "gitleaks", len(found), blocking, f"max {policy['max_findings']} findings"


def image(reports, policy):
    data = load(reports / "trivy-image.json")
    total, blocking, seen = 0, [], set()
    for result in data.get("Results", []):
        for v in result.get("Vulnerabilities") or []:
            total += 1
            fixable = bool(v.get("FixedVersion"))
            if v["Severity"] in policy["block_severity"] and (
                fixable or not policy["ignore_unfixed"]
            ):
                key = (v["VulnerabilityID"], v["PkgName"])
                if key not in seen:
                    seen.add(key)
                    blocking.append(
                        f"{v['Severity']} {v['VulnerabilityID']} {v['PkgName']} "
                        f"{v['InstalledVersion']} -> {v.get('FixedVersion') or 'no fix'}"
                    )
    rule = f"{'/'.join(policy['block_severity'])}" + (
        " with a fix" if policy["ignore_unfixed"] else ""
    )
    return "Image", "trivy", total, blocking, rule


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("reports", type=Path)
    ap.add_argument("--summary", help="append a markdown table to this file")
    args = ap.parse_args()
    policy = tomllib.loads(POLICY.read_text())

    rows = []
    for name, check in (("sast", sast), ("sca", sca), ("secrets", secrets), ("image", image)):
        try:
            rows.append(check(args.reports, policy[name]))
        except (OSError, ValueError, KeyError) as exc:
            rows.append(
                (
                    name.upper(),
                    "?",
                    "-",
                    [f"report missing or unreadable: {exc}"],
                    "report required",
                )
            )

    print(f"{'CONTROL':<8} {'TOOL':<10} {'FINDINGS':>8} {'BLOCKING':>8}  {'RESULT':<6} THRESHOLD")
    for control, tool, total, blocking, rule in rows:
        verdict = "FAIL" if blocking else "PASS"
        print(f"{control:<8} {tool:<10} {total:>8} {len(blocking):>8}  {verdict:<6} {rule}")
    for control, _, _, blocking, _ in rows:
        for line in blocking[:15]:
            print(f"  [{control}] {line}")
        if len(blocking) > 15:
            print(f"  [{control}] ... and {len(blocking) - 15} more")

    failed = [r[0] for r in rows if r[3]]
    decision = f"BLOCKED by {', '.join(failed)}" if failed else "PASSED - image may be pushed"
    print(f"\nSECURITY GATE: {decision}")

    if args.summary:
        with open(args.summary, "a") as fh:
            fh.write("### Security gate\n\n| Control | Tool | Findings | Blocking | Result |\n")
            fh.write("|---|---|---|---|---|\n")
            for control, tool, total, blocking, _ in rows:
                fh.write(f"| {control} | {tool} | {total} | {len(blocking)} | ")
                fh.write(f"{'FAIL' if blocking else 'PASS'} |\n")
            fh.write(f"\n**{decision}**\n")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
