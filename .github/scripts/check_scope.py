#!/usr/bin/env python3
"""Scope-only guard. Never imports or executes proposal code."""
import argparse
import base64
import copy
import datetime
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

CHECK_NAME = "Scope boundary"
TASK_RE = re.compile(r"^codex/(gpt|grok|codex)/(task-[0-9]{3,})$")
OWNER_RE = re.compile(r"^codex/owner/approve-(gpt|grok|codex)-(task-[0-9]{3,})$")


def clean_path(path):
    if not isinstance(path, str) or not path or path.startswith("/") or "\\" in path or ":" in path or any(ord(c) < 32 for c in path):
        return False
    parts = path.rstrip("/").split("/")
    return all(p and p not in (".", "..") and p != ".git" for p in parts)


def validate_grant(grant, repository, bot, task_id, require_approved=True):
    errors = []
    game_root = "sandbox/" + bot + "/" + task_id + "/"
    report_root = "discussions/" + bot + "/" + task_id + "/"
    permitted_roots = [report_root] if grant.get("status") == "REPORTS_ONLY" else [game_root, report_root]
    expected = {"schema_version": 1, "repository": repository, "bot": bot,
                "task_id": task_id, "branch": "codex/" + bot + "/" + task_id}
    for key, value in expected.items():
        if grant.get(key) != value:
            errors.append("Grant field mismatch: " + key)
    if grant.get("status") not in ("PENDING_USER_AUTHORIZATION", "REPORTS_ONLY", "APPROVED", "REVOKED"):
        errors.append("Unknown grant status")
    if require_approved and grant.get("status") not in ("APPROVED", "REPORTS_ONLY"):
        errors.append("Task has no active human authorization")
    roots = grant.get("allowed_write_roots")
    if not isinstance(roots, list) or not roots:
        errors.append("Missing allowed write roots")
    else:
        for item in roots:
            if not clean_path(item) or not item.endswith("/") or not any(item.startswith(root) for root in permitted_roots):
                errors.append("Write root escapes the assigned bot/task directory")
    if not re.fullmatch(r"[0-9a-f]{64}", str(grant.get("baseline_manifest_sha256", ""))):
        errors.append("Missing baseline manifest identity")
    if grant.get("status") in ("APPROVED", "REPORTS_ONLY"):
        auth = grant.get("authorization")
        if not isinstance(auth, dict):
            errors.append("Missing human authorization record")
        elif (auth.get("issued_by") != repository.split("/")[0]
              or not isinstance(auth.get("human_request"), str)
              or not auth.get("human_request", "").strip()
              or not isinstance(auth.get("approved_at"), str)):
            errors.append("Invalid human authorization record")
        else:
            try:
                stamp = datetime.datetime.fromisoformat(auth["approved_at"].replace("Z", "+00:00"))
                if stamp.tzinfo is None:
                    raise ValueError("timezone required")
            except ValueError:
                errors.append("Invalid authorization timestamp")
        if not isinstance(grant.get("objective"), str) or not grant.get("objective", "").strip():
            errors.append("Missing approved objective")
    if not isinstance(grant.get("allowed_tests"), list):
        errors.append("Missing allowed-tests list")
    return errors


def evaluate_task(grant, repository, branch, files, modes):
    match = TASK_RE.fullmatch(branch)
    if not match:
        return ["Unknown bot/task branch"]
    bot, task_id = match.groups()
    errors = validate_grant(grant, repository, bot, task_id)
    roots = grant.get("allowed_write_roots", [])
    valid_roots = [r for r in roots if isinstance(r, str) and clean_path(r)] if isinstance(roots, list) else []
    if not files:
        errors.append("No proposal files")
    for item in files:
        for name in (item.get("filename"), item.get("previous_filename")):
            if name is None:
                continue
            if not clean_path(name) or not any(name.startswith(root) for root in valid_roots):
                errors.append("Out-of-scope path: " + str(name))
        name = item.get("filename")
        if grant.get("status") == "REPORTS_ONLY" and isinstance(name, str) and not name.endswith((".txt", ".md")):
            errors.append("REPORTS_ONLY permits text/Markdown documents only: " + name)
        if not name:
            errors.append("Missing changed filename")
        if modes.get(name) in ("120000", "160000"):
            errors.append("Symlink/submodule is not allowed: " + str(name))
    return errors


def evaluate_owner(branch, repository, head_repository, author, files, grant):
    match = OWNER_RE.fullmatch(branch)
    if not match:
        return ["Unknown owner-maintenance branch"]
    bot, task_id = match.groups()
    target = "tasks/" + bot + "/" + task_id + ".json"
    errors = []
    if head_repository != repository or author != repository.split("/")[0]:
        errors.append("Owner grant maintenance must be from the owner in the same repository")
    if len(files) != 1 or files[0].get("filename") != target or files[0].get("previous_filename") or files[0].get("status") == "removed":
        errors.append("Owner grant update may change only its exact grant JSON")
    errors.extend(validate_grant(grant, repository, bot, task_id, require_approved=False))
    return errors


def self_test():
    repo = "example/GnomiT-review-test"
    def approved(bot="gpt"):
        return {"schema_version": 1, "repository": repo, "bot": bot, "task_id": "task-001",
                "branch": "codex/" + bot + "/task-001", "status": "APPROVED",
                "allowed_write_roots": ["sandbox/" + bot + "/task-001/"],
                "baseline_manifest_sha256": "a" * 64, "objective": "Only improve walking",
                "allowed_tests": ["runtime"],
                "authorization": {"issued_by": "example", "approved_at": "2026-10-14T10:00:00Z",
                                  "human_request": "I authorize this bounded task"}}
    file = {"filename": "sandbox/gpt/task-001/game/scripts/slice_map_view.gd", "status": "modified"}
    passed = []
    def case(name, grant=None, files=None, modes=None, branch="codex/gpt/task-001", allowed=False):
        result = evaluate_task(grant if grant is not None else approved(), repo, branch,
                               files if files is not None else [file], modes or {})
        assert (not result) == allowed, (name, result)
        passed.append(name)
    case("approved own code", allowed=True)
    case("approved own outputs", files=[{"filename": "sandbox/gpt/task-001/outputs/report.md"}], allowed=True)
    case("own deletion", files=[{**file, "status": "removed"}], allowed=True)
    case("other bot correctly assigned", grant=approved("grok"), branch="codex/grok/task-001",
         files=[{"filename": "sandbox/grok/task-001/game/scripts/main.gd"}], allowed=True)
    grant = approved(); grant["status"] = "PENDING_USER_AUTHORIZATION"; grant["authorization"] = None
    case("pending permission", grant=grant)
    grant = approved(); grant["status"] = "REVOKED"; case("revoked permission", grant=grant)
    grant = approved(); grant["authorization"] = None; case("missing human record", grant=grant)
    grant = approved(); grant["authorization"]["issued_by"] = "bot"; case("self authorization", grant=grant)
    grant = approved(); grant["repository"] = "example/private-game"; case("wrong repository", grant=grant)
    case("other bot folder", files=[{"filename": "sandbox/grok/task-001/outputs/x.txt"}])
    case("baseline change", files=[{"filename": "baseline/game/scripts/main.gd"}])
    case("policy rewrite", files=[{"filename": ".github/workflows/scope-check.yml"}])
    case("self grant edit", files=[{"filename": "tasks/gpt/task-001.json"}])
    case("rename outside to inside", files=[{**file, "previous_filename": "baseline/game/scripts/main.gd"}])
    case("traversal", files=[{"filename": "sandbox/gpt/task-001/../../grok/x"}])
    case("absolute path", files=[{"filename": "/sandbox/gpt/task-001/x"}])
    case("backslash path", files=[{"filename": "sandbox/gpt/task-001/a\\b"}])
    case("prefix collision", files=[{"filename": "sandbox/gpt/task-001-extra/x"}])
    case("unknown branch", branch="codex/gpt/other")
    case("symlink", modes={file["filename"]: "120000"})
    case("submodule", modes={file["filename"]: "160000"})
    grant = approved(); grant["allowed_write_roots"] = ["sandbox/"]; case("broad grant rejected", grant=grant)
    grant = approved(); grant["allowed_write_roots"] = ["sandbox/gpt/task-001/outputs/"]
    case("narrow grant enforced", grant=grant)
    grant = approved(); grant["status"] = "REPORTS_ONLY"; grant["allowed_write_roots"] = ["discussions/gpt/task-001/"]
    case("report-only own text", grant=grant, files=[{"filename": "discussions/gpt/task-001/REPORT.txt"}], allowed=True)
    case("report-only code rejected", grant=grant)
    case("report-only script in report folder rejected", grant=grant, files=[{"filename": "discussions/gpt/task-001/run.py"}])
    case("report-only other report rejected", grant=grant, files=[{"filename": "discussions/grok/task-001/REPORT.txt"}])
    grant["allowed_write_roots"] = ["sandbox/gpt/task-001/"]; case("report-only cannot broaden grant", grant=grant)
    owner_file = [{"filename": "tasks/gpt/task-001.json", "status": "modified"}]
    assert not evaluate_owner("codex/owner/approve-gpt-task-001", repo, repo, "example", owner_file, approved())
    passed.append("owner exact grant update")
    assert evaluate_owner("codex/owner/approve-gpt-task-001", repo, "other/fork", "example", owner_file, approved())
    passed.append("owner fork rejected")
    assert evaluate_owner("codex/owner/approve-gpt-task-001", repo, repo, "other", owner_file, approved())
    passed.append("non-owner grant update rejected")
    assert evaluate_owner("codex/owner/approve-gpt-task-001", repo, repo, "example", owner_file + [file], approved())
    passed.append("owner code update rejected")
    print(json.dumps({"status": "PASS", "cases": len(passed), "tests": passed}, indent=2))
    return passed


def api(method, path, payload=None):
    token = os.environ["GH_TOKEN"]
    request = urllib.request.Request("https://api.github.com" + path, method=method,
        headers={"Authorization": "Bearer " + token, "Accept": "application/vnd.github+json",
                 "User-Agent": "GnomiT-scope-boundary", "X-GitHub-Api-Version": "2022-11-28"},
        data=None if payload is None else json.dumps(payload).encode())
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


def read_json(repo, path, ref):
    obj = api("GET", "/repos/" + repo + "/contents/" + urllib.parse.quote(path, safe="/") + "?ref=" + urllib.parse.quote(ref, safe=""))
    return json.loads(base64.b64decode(obj["content"]))


def run_event():
    if os.environ.get("GITHUB_EVENT_NAME") != "pull_request_target":
        self_test()
        return
    with open(os.environ["GITHUB_EVENT_PATH"], encoding="utf-8") as stream:
        event = json.load(stream)
    repo = os.environ["GITHUB_REPOSITORY"]
    number = event["number"]
    pull = api("GET", "/repos/" + repo + "/pulls/" + str(number))
    head = pull["head"]["sha"]
    base = pull["base"]["sha"]
    branch = pull["head"]["ref"]
    errors = []
    try:
        if pull["base"]["ref"] != "main":
            raise ValueError("Base branch must be main")
        # Script was loaded from the event's trusted base. Reject stale base policy.
        if base != os.environ["TRUSTED_BASE_SHA"]:
            raise ValueError("Base changed; rerun the check with current main")
        files = []
        for page in range(1, 31):
            batch = api("GET", "/repos/" + repo + "/pulls/" + str(number) + "/files?per_page=100&page=" + str(page))
            files.extend(batch)
            if len(batch) < 100:
                break
        if len(files) != pull["changed_files"]:
            raise ValueError("Incomplete changed-file listing")
        tree = api("GET", "/repos/" + repo + "/git/trees/" + head + "?recursive=1")
        if tree.get("truncated"):
            raise ValueError("Head tree truncated")
        modes = {x["path"]: x["mode"] for x in tree["tree"]}
        owner_match = OWNER_RE.fullmatch(branch)
        if owner_match:
            bot, task_id = owner_match.groups()
            path = "tasks/" + bot + "/" + task_id + ".json"
            grant = read_json(repo, path, head)  # Owner JSON is data only, never executed.
            errors = evaluate_owner(branch, repo, pull["head"]["repo"]["full_name"], pull["user"]["login"], files, grant)
            if modes.get(path) != "100644":
                errors.append("Owner grant must be a regular JSON file")
        else:
            match = TASK_RE.fullmatch(branch)
            if not match:
                raise ValueError("Unknown task branch")
            bot, task_id = match.groups()
            grant = read_json(repo, "tasks/" + bot + "/" + task_id + ".json", base)
            manifest = api("GET", "/repos/" + repo + "/contents/baseline/MANIFEST.json?ref=" + base)
            import hashlib
            actual_manifest = hashlib.sha256(base64.b64decode(manifest["content"])).hexdigest()
            errors = evaluate_task(grant, repo, branch, files, modes)
            if grant.get("baseline_manifest_sha256") != actual_manifest:
                errors.append("Baseline manifest identity mismatch")
        current = api("GET", "/repos/" + repo + "/pulls/" + str(number))
        if current["head"]["sha"] != head or current["base"]["sha"] != base:
            errors.append("Proposal changed during verification; rerun required")
    except Exception as exc:
        errors.append(type(exc).__name__ + ": " + str(exc))
    conclusion = "failure" if errors else "success"
    now = datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z")
    api("POST", "/repos/" + repo + "/check-runs", {
        "name": CHECK_NAME, "head_sha": head, "status": "completed", "conclusion": conclusion,
        "completed_at": now,
        "details_url": "https://github.com/" + repo + "/actions/runs/" + os.environ["GITHUB_RUN_ID"],
        "output": {"title": "Scope " + conclusion, "summary": "\n".join(errors)[:60000] if errors else "Approved task; all proposal paths are inside the registered scope. No proposal code executed."}})
    print(json.dumps({"scope": conclusion, "head": head, "branch": branch, "errors": errors}, indent=2))
    if errors:
        raise SystemExit(1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--self-test", action="store_true")
    parser.add_argument("--github-event", action="store_true")
    args = parser.parse_args()
    if args.self_test:
        self_test()
    elif args.github_event:
        run_event()
    else:
        parser.error("Select --self-test or --github-event")
