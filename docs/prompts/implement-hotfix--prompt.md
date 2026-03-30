Implement a narrow hotfix on the current stable branch for the integrated PR workflows.

**Problem**

- The defect is not Linux SSH, GitHub device auth, or the local environment.
- The defect is that the integrated PR handlers force the push remote to HTTPS and then invoke git non-interactively, which fails with `fatal: could not read Username for 'https://github.com': terminal prompts disabled`.
- Fix the PR push path so it preserves or constructs an SSH-compatible remote instead of forcing HTTPS.

**Read these files first**

- `docs/reports/04_manual-linux-ssh-validation-notes.md`
- `docs/reports/02_phase1-linux-ssh-git-auth-foundation-report.md`
- `docs/architecture/decisions/ADR-001-fork-remote-policy-for-integrated-pr-workflows.md`
- `docs/architecture/decisions/ADR-004-clone-scope-boundary-for-initial-linux-ssh-release.md`

**Then inspect these likely implementation surfaces**

- `Views/GitTabView.axaml.cs`
- `Services/GitRepoService.cs`

**Search for all code that computes, normalizes, or overwrites PR push remotes, including any use of:**

- `remoteUrlClean`
- `EnsureRemoteUrlAsync`
- `https://github.com/`
- fork remote URL construction
- integrated PR handlers
- `git push`

**Required scope**

- Implement the hotfix end to end. Do not stop at analysis.
- Patch only the integrated PR push path.
- Preserve any existing SSH-compatible push remote.
- If the app must synthesize or select a fork remote for PR creation, synthesize/select an SSH-compatible remote instead of an HTTPS remote.
- Reuse existing helpers and conventions where possible.
- Keep the change set as narrow as possible.

**Out of scope**

- Do not change clone behavior.
- Do not change onboarding or `RepoUrl` behavior unless a hard dependency makes a minimal adjustment unavoidable.
- Do not broaden this into a general transport refactor.
- Do not change GitHub device auth or PR creation logic unless required by the push-path fix.

**Implementation constraints**

- The single-file PR flow and the community-data PR flow both need to be covered if they currently force HTTPS.
- If `Services/GitRepoService.cs` must change, keep it limited to the minimum needed to support SSH-compatible preservation/construction for the integrated PR workflows.
- Do not replace a valid SSH remote with a different remote form unless necessary.
- Prefer root-cause fixes over branch-specific hacks.
- Follow existing repo patterns, naming, and error-handling style.

**Acceptance criteria**

- The integrated PR workflows no longer overwrite an SSH-capable push path with HTTPS.
- If a fork remote is synthesized for push, it is SSH-compatible.
- Existing SSH-ready Linux workflows no longer fail because the app selected an HTTPS push remote.
- Clone-path behavior remains unchanged.
- The final diff is narrowly scoped to the PR-handler/push-remote hotfix.

**At the end**

- Summarize the root cause in 1-2 sentences.

- List the exact files changed.

- State exactly how the HTTPS rewrite was removed or replaced.

- Report any verification performed.

- If you hit a blocker, name the blocker precisely and identify the smallest unresolved code path.
