"""Offline regression checks: python3 ~/.config/fish/tests/test_pr_report.py."""

import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import tempfile
import unittest


FUNCTION = Path(__file__).resolve().parents[1] / "functions/pr-report.fish"


class ReportTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="pr-report-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.rows = self.root / "rows.tsv"
        self.calls = self.root / "jira-calls"
        self.env = dict(os.environ, PATH=f"{self.root}:{os.environ['PATH']}", PR_REPORT_JIRA_SITE="example.atlassian.net")
        self.env["PR_REPORT_TEST_ROOT"] = str(self.root)
        scripts = {
            "git": '#!/bin/sh\nprintf "git@github.com:example/repo.git\\n"\n',
            "gh": '''#!/usr/bin/env python3
import json, os, pathlib, sys
root = pathlib.Path(os.environ["PR_REPORT_TEST_ROOT"])
(root / "gh-args.json").write_text(json.dumps(sys.argv[1:]))
rows = (root / "rows.tsv").read_text()
if "includeMergeState=false" in sys.argv:
    # Match the jq projection when GraphQL omits the optional final field.
    rows = "".join("\\t".join(row.split("\\t")[:15] + [""]) + "\\n" for row in rows.splitlines())
sys.stdout.write(rows)
sys.exit(int(os.environ.get("PR_REPORT_TEST_GH_EXIT", "0")))
''',
            "acli": '''#!/bin/sh
printf '%s\n' "$*" >> "$PR_REPORT_TEST_ROOT/jira-calls"
if [ "$*" = 'jira auth status' ]; then
    printf 'Site: example.atlassian.net\n'
else
    printf '[{"key":"FLYWL-2","fields":{"status":{"name":"Code Review"}}}]\n'
fi
''',
        }
        for name, text in scripts.items():
            path = self.root / name
            path.write_text(text)
            path.chmod(0o700)
        # Deliberately scramble PR number, title, review state and draft status.
        cases = [
            (100, "Alpha", False, "REVIEW_REQUIRED", "", "CONFLICTING", 0),
            (20, "Beta", True, "REVIEW_REQUIRED", "", "MERGEABLE", 0),
            (10, "Zulu", False, "APPROVED", "copilot", "MERGEABLE", 0),
            (1, "Gamma", True, "REVIEW_REQUIRED", "", "MERGEABLE", 2),
            (2, "Omega", False, "APPROVED", "", "MERGEABLE", 0),
        ]
        rows = []
        for number, title, draft, review, requested, mergeable, threads in cases:
            rows.append("\t".join(map(str, [
                number, f"FLYWL-{number}: {title}", f"feature/FLYWL-{number}-test",
                review, 5, 0, 0, "backend,Ready For Review", threads,
                f"https://github.com/example/repo/pull/{number}", 0, 0,
                str(draft).lower(), requested, mergeable, "CLEAN",
            ])))
        self.rows.write_text("\n".join(rows) + "\n")

    def run_report(self, *args, success=True):
        command = f"source {shlex.quote(str(FUNCTION))}; pr-report {shlex.join(args)}"
        result = subprocess.run(
            ["fish", "--no-config", "-c", command], env=self.env,
            capture_output=True, text=True, timeout=15,
        )
        self.assertEqual(result.returncode, 0 if success else 1, result.stderr)
        return result.stdout

    @staticmethod
    def numbers(output):
        output = re.sub(r"\x1b\]8;;[^\x07]*\x07", "", output)
        return list(map(int, re.findall(r"#(\d+)", output)))

    def test_order_in_all_output_modes(self):
        for mode in [("--short",), (), ("--slack",)]:
            with self.subTest(mode=mode):
                self.assertEqual(self.numbers(self.run_report("--all", *mode)), [2, 10, 100, 1, 20])
        rows = json.loads(self.run_report("--all", "--json"))
        self.assertEqual([row["number"] for row in rows], [2, 10, 100, 1, 20])
        self.assertEqual(rows[0]["jira"]["status"], "Code Review")
        self.assertTrue(rows[2]["hasMergeConflicts"])
        self.assertEqual(rows[1]["requestedReviewers"], ["copilot"])
        self.assertEqual(rows[3]["copilotUnresolved"], 2)

    def test_short_links_without_any_jira_calls(self):
        output = self.run_report("--short")
        self.assertEqual(self.numbers(output), [2, 10, 100])
        self.assertIn("https://example.atlassian.net/browse/FLYWL-2", output)
        self.assertFalse(self.calls.exists())

    def test_short_without_site_has_no_links(self):
        self.env.pop("PR_REPORT_JIRA_SITE")
        output = self.run_report("--short")
        self.assertNotIn("atlassian.net/browse", output)
        self.assertFalse(self.calls.exists())

    def test_unfiltered_short_skips_full_merge_state(self):
        output = self.run_report("--all", "--short")
        args = json.loads((self.root / "gh-args.json").read_text())
        self.assertIn("includeMergeState=false", args)
        query = next(arg for arg in args if arg.startswith("query="))
        self.assertIn("mergeStateStatus @include(if:$includeMergeState)", query)
        self.assertIn("--paginate", args)
        self.assertIn("mergeable", query)
        self.assertIn("statusCheckRollup", query)
        self.assertIn("reviewThreads(first:100)", query)
        self.assertEqual(self.numbers(output), [2, 10, 100, 1, 20])
        # Conflict and draft markers still align with the appended TSV fields.
        self.assertIn("", next(line for line in output.splitlines() if "#100" in line))
        self.assertIn("◆", next(line for line in output.splitlines() if "#20" in line))

    def test_filtered_short_keeps_raw_merge_state_filtering(self):
        rows = self.rows.read_text().splitlines()
        fields = rows[-1].split("\t")
        fields[15] = "BLOCKED"
        self.rows.write_text("\n".join(rows[:-1] + ["\t".join(fields)]) + "\n")
        self.assertEqual(self.numbers(self.run_report("--short", "blocked")), [2])
        args = json.loads((self.root / "gh-args.json").read_text())
        self.assertIn("includeMergeState=true", args)

    def test_full_modes_keep_merge_state_and_conflict_fallback(self):
        rows = self.rows.read_text().splitlines()
        fields = rows[0].split("\t")
        fields[14:16] = ["UNKNOWN", "DIRTY"]
        self.rows.write_text("\n".join(["\t".join(fields)] + rows[1:]) + "\n")
        for mode in [(), ("--slack",), ("--json",), ("--short", "--json")]:
            with self.subTest(mode=mode):
                output = self.run_report(*mode)
                args = json.loads((self.root / "gh-args.json").read_text())
                self.assertIn("includeMergeState=true", args)
                if "--json" in mode:
                    row = next(row for row in json.loads(output) if row["number"] == 100)
                    self.assertEqual(row["mergeStateStatus"], "DIRTY")
                    self.assertTrue(row["hasMergeConflicts"])

    def test_no_jira_disables_links_and_calls(self):
        output = self.run_report("--short", "--no-jira")
        self.assertNotIn("atlassian.net", output)
        self.assertFalse(self.calls.exists())

    def test_slack_skips_jira(self):
        self.run_report("--slack")
        self.assertFalse(self.calls.exists())

    def test_filters_and_state_markers(self):
        self.assertEqual(self.numbers(self.run_report("--short", "attention")), [])
        self.assertEqual(self.numbers(self.run_report("--short", "conflict")), [100])
        self.assertEqual(self.numbers(self.run_report("--all", "--short", "!conflict")), [2, 10, 1, 20])
        output = self.run_report("--short", "Zulu")
        self.assertIn("󰍉", output)
        self.assertNotIn("✓", output)

    def test_json_still_enriches_when_short_flag_is_present(self):
        rows = json.loads(self.run_report("--short", "--json"))
        self.assertEqual(rows[0]["jira"]["status"], "Code Review")
        self.assertEqual(self.calls.read_text().splitlines()[0], "jira auth status")

    def test_empty_and_failed_github_results(self):
        self.rows.write_text("")
        self.assertEqual(json.loads(self.run_report("--json", "--no-jira")), [])
        self.env["PR_REPORT_TEST_GH_EXIT"] = "1"
        output = self.run_report("--short", success=False)
        self.assertNotIn("All clear", output)


if __name__ == "__main__":
    unittest.main()
