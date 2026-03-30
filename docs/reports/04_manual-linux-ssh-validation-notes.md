# Manual Linux Validation Notes — Linux SSH Git Auth

**Date:** 2026-03-15  
**Feature Context:** Linux SSH Git authentication for integrated Git workflows  
**Purpose:** Record manual Linux validation evidence relevant to the current SSH transport defect, the non-interactive SSH support contract, and the integrated PR workflow design.

## Summary

These notes establish two facts.

1. The Linux environment under test is already **non-interactive SSH-ready** for GitHub SSH transport.
2. The current in-app integrated PR workflow still fails because it **forces an HTTPS fork remote** and then attempts a non-interactive HTTPS push, which fails with terminal prompts disabled.

Taken together, these notes support the current design direction:

- the Linux environment can satisfy the proposed non-interactive SSH contract;
- the present product defect is the integrated PR workflow’s forced-HTTPS remote handling, not a lack of SSH capability on Linux;
- unsupported prompt-dependent SSH behavior remains a separate negative class that is still not directly exercised here.

---

# Note 1: Positive Case — Existing Repo, Non-Interactive SSH Ready

## Environment
- OS / distro: Linux workstation
- Repository under test: existing local repository
- Local repository path: `~/code/third-party/CBETA-Translator`
- Existing remotes:
  - `origin = git@github.com:nmetrock/CBETA-Translator.git`
  - `upstream = git@github.com:Fabulu/CBETA-Translator.git`
- Target fork checked for SSH transport:
  - `git@github.com:nmetrock/CbetaZenTexts.git`
- `GIT_TERMINAL_PROMPT=0`: confirmed in command invocation
- GitHub SSH identity: `nmetrock`

## Preconditions
- The local repository already exists.
- The local repository uses SSH-compatible remotes.
- GitHub SSH access is configured in the user environment.
- This case is intended to validate the proposed initial-release non-interactive SSH support contract.

## Action

### 1. Inspect existing remotes
```bash
git remote -v
````

Observed:

```bash
origin	git@github.com:nmetrock/CBETA-Translator.git (fetch)
origin	git@github.com:nmetrock/CBETA-Translator.git (push)
upstream	git@github.com:Fabulu/CBETA-Translator.git (fetch)
upstream	git@github.com:Fabulu/CBETA-Translator.git (push)
```

### 2. Verify SSH authentication to GitHub

```bash
ssh -T git@github.com
```

Observed:

```bash
Hi nmetrock! You've successfully authenticated, but GitHub does not provide shell access.
```

### 3. Verify non-interactive SSH Git transport to the fork

```bash
GIT_TERMINAL_PROMPT=0 git ls-remote git@github.com:nmetrock/CbetaZenTexts.git
```

Observed:

```bash
f65dff124705c6dfe8ba63e1759454271a94dd5e	HEAD
4d2f6254b86a902ce05fba30e65aafc8409dd905	refs/heads/community/data/20260302-233335
f7a1abfc3106c8da2b2923ea6ca40f97619bc78b	refs/heads/contrib/J/J24/J24nB137.xml/20260225-165103
f12548c7307da4d3d3578728a244cd401b3e3d5b	refs/heads/contrib/J/J24/J24nB137.xml/20260226-085953
a24b43f4a4c5626782e97cab34a02416fb76ba5f	refs/heads/contrib/T/T47/T47n1987A.xml/20260211-215336
f9e782f44671146424c570ec539e1a7abe5d728e	refs/heads/contrib/T/T47/T47n1987A.xml/20260224-151033
cd68e0bb1d4d98495a7849d66c7ec03c4beec8c4	refs/heads/contrib/T/T47/T47n1987A.xml/20260224-154837
75eb958d5be16e1854d80fa8236127377afeaf84	refs/heads/contrib/T/T47/T47n1987B.xml/20260224-161242
c7c21575ea07c89bf013f0431cb6e631f0f7e8d3	refs/heads/contrib/T/T47/T47n1987B.xml/20260224-163122
3ac55e418520018a7c1146e05535edad5eee8d3c	refs/heads/contrib/T/T47/T47n1987B.xml/20260226-134211
31d500c655aed8033d60b95c4ddb3f09bebc33a1	refs/heads/contrib/T/T48/T48n2004.xml/20260226-110520
dd16cb3a453f61926863d1b5ae971a5c7de37562	refs/heads/contrib/T/T48/T48n2004.xml/20260226-110848
e586fc4da2f9cf74acc92ec30aff2cd1f350cb60	refs/heads/contrib/T/T48/T48n2010.xml/20260226-111155
f65dff124705c6dfe8ba63e1759454271a94dd5e	refs/heads/main
```

## Interpretation

- The local repository is SSH-configured already.
- Host trust and SSH authentication are already working for GitHub.
- A Git operation against the target fork succeeds under `GIT_TERMINAL_PROMPT=0`.
- This environment is therefore **non-interactive SSH-ready**.
- This supports the proposed initial-release Linux SSH support contract:
  - supported workflows can succeed without GCM,
  - supported workflows can rely on the user’s existing SSH environment,
  - non-interactive SSH transport is viable on this Linux machine.

## Conclusion

The positive case is confirmed. Linux SSH Git transport works non-interactively in the tested environment, including against the relevant fork, without Git Credential Manager.

---

# Note 2: Negative Case — Current In-App PR Workflow Forces HTTPS and Fails Non-Interactively

## Environment

- OS / distro: Linux workstation
- App workflow under test: integrated Git tab contribution flow
- Repository context: existing local repository
- Git executable used by app: `/usr/bin/git`
- GitHub device auth in app: successful (`user: nmetrock`)
- Local SSH readiness: confirmed separately in Note 1
- Workflow under test: `Create local commit` → `Authorize GitHub` → `Push + Create PR`

## Preconditions

- A local contribution commit can be created through the app.
- GitHub device authorization succeeds in the app.
- The machine’s Linux environment is already SSH-ready outside the app.
- This case is intended to observe the current integrated PR workflow behavior before any implementation fix.

## Action

### Stage 1: Create local commit (single file)

Observed log:

```text
[map] cbeta: X/X63/X63n1217.xml
[map] repo : xml-p5t/X/X63/X63n1217.xml
[git] .git/info/exclude ok (local)
[git] exe: /usr/bin/git [system-or-path]
[git] exe: /usr/bin/git [system-or-path]
[git] line endings configured (local): autocrlf=false, eol=lf
[git] user identity ok
[git] current branch: main
[step] git add -- xml-p5t/X/X63/X63n1217.xml
[git] exe: /usr/bin/git [system-or-path]
[step] git stash push -u -k
[git] exe: /usr/bin/git [system-or-path]
Saved working directory and index state On main: cbeta-autostash
[step] new branch: contrib/X/X63/X63n1217.xml/20260310-152954
[step] commit message: Translation for Bodhidharma: Four Practices (1217); No Preface (1217-A), No Eulogy (1217-B)
[git] exe: /usr/bin/git [system-or-path]
Switched to a new branch 'contrib/X/X63/X63n1217.xml/20260310-152954'
[git] exe: /usr/bin/git [system-or-path]
[contrib/X/X63/X63n1217.xml/20260310-152954 af5c222] Translation for Bodhidharma: Four Practices (1217); No Preface (1217-A), No Eulogy (1217-B)
[ok] created single-file commit on branch: contrib/X/X63/X63n1217.xml/20260310-152954
[next] 2) Authorize GitHub, then 3) Push + Create PR
[restore] switching back to: main
 1 file changed, 162 insertions(+), 74 deletions(-)
[git] exe: /usr/bin/git [system-or-path]
Switched to branch 'main'
[restore] stash pop
Your branch is up to date with 'origin/main'.
[git] exe: /usr/bin/git [system-or-path]
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   xml-p5t/X/X63/X63n1217.xml
	modified:   zen_texts.json

no changes added to commit (use "git add" and/or "git commit -a")
Dropped refs/stash@{0} (54c1870db9edeac2b94259bc900b5091bb78bcc3)
```

Interpretation:

- Local contribution commit preparation succeeded.
- This stage is consistent with a transport-only/local-only action.
- No GitHub transport evidence is implied by this stage.

### Stage 2: Authorize GitHub

Observed log:

```text
[auth] requesting device code…
[auth] Go to: https://github.com/login/device
[auth] Enter code: 808C-5FD9
[auth] Opening browser…
[auth] waiting for authorization…
[auth] success.
[auth] user: nmetrock
```

Interpretation:

- GitHub API authentication succeeded in the app.
- This stage confirms GitHub account capability for later API-backed stages.
- It does not validate Git transport capability.

### Stage 3: Push + Create PR

Observed log:

```text
[step] create fork
[step] remote fork -> https://github.com/nmetrock/CbetaZenTexts.git
[git] exe: /usr/bin/git [system-or-path]
[step] ensuring local credential helper
[step] push -u fork contrib/X/X63/X63n1217.xml/20260310-152954
[hint] If Git opens a browser/device login, complete it and retry if needed.
[git] credential helper bootstrap skipped (non-Windows)
[git] exe: /usr/bin/git [system-or-path]
fatal: could not read Username for 'https://github.com': terminal prompts disabled
[error] fatal: could not read Username for 'https://github.com': terminal prompts disabled
[hint] Git could not open a login prompt.
[hint] On Windows, the shipped Git may be missing Git Credential Manager files.
```

## Interpretation

- The current integrated PR workflow selected or created an **HTTPS** fork remote:
  - `https://github.com/nmetrock/CbetaZenTexts.git`

- The push then attempted to use that HTTPS remote in a non-interactive Git process.
- The push failed because Git could not prompt for HTTPS credentials:
  - `fatal: could not read Username for 'https://github.com': terminal prompts disabled`

- This failure occurred **after** GitHub device authorization had already succeeded.
- Therefore this is **not** evidence that GitHub API auth failed.
- This is also **not** evidence that SSH transport failed.
- Given the positive SSH evidence in Note 1, the most accurate classification is:
  - **primary defect:** integrated PR workflow remote/protocol handling forces HTTPS
  - **manifested failure:** non-interactive HTTPS credential failure

- This negative case therefore supports the claim that the current Linux contribution failure is caused by the mixed PR workflow’s forced-HTTPS path, not by lack of SSH capability on Linux.

## Failure Class

- Primary class: remote/protocol handling defect in integrated PR workflow
- Manifested as: non-interactive HTTPS auth failure
- Not supported by evidence:
  - GitHub API auth failure
  - Linux SSH transport failure
  - contradiction of the positive non-interactive SSH support case

## Conclusion

The current `Push + Create PR` Linux failure is a workflow-path defect, not a failure of SSH readiness. The app completes the local commit stage and GitHub auth stage, then fails only after selecting an HTTPS fork remote and attempting a non-interactive HTTPS push.

---

# Overall Assessment

## What these notes prove

- Linux SSH transport can succeed non-interactively in the tested environment.
- The app’s current integrated PR workflow still routes the contribution path through HTTPS.
- The observed Linux failure is therefore caused by forced HTTPS remote handling, not by absence of working SSH capability.
- Git transport capability and GitHub API capability are separate in reality and must remain separate in the product model.

## What these notes do not yet prove

- They do not exercise a first-use host-key prompt case.
- They do not yet show a direct negative SSH case such as missing host trust, missing agent, or rejected SSH auth.
- They therefore support the positive side of the proposed Linux SSH support contract and the current PR-workflow defect, but they do not fully close all negative-case validation for prompt-dependent SSH behavior.

## Recommended use in the next session

Use these notes as:

- the manual Linux validation input requested by the Phase 1 report,
- supporting evidence for the C3 fork-remote-handling implementation plan,
- supporting evidence for the C4 non-interactive SSH support contract,
- supporting evidence that the current Linux failure is specifically the forced-HTTPS PR-path defect.

## Traceability

- Relevant design boundary: transport capability and GitHub API capability remain separate.
- Relevant PR-workflow finding: integrated PR flows currently rewrite remotes to HTTPS before push.
- Relevant support-contract question: supported Linux SSH assumes a non-interactive-ready environment.
- Relevant RTM requirements:

  - `LSGA-C3-001`
  - `LSGA-C3-002`
  - `LSGA-C4-001`
  - `LSGA-C4-002`
  - `LSGA-X-001`
