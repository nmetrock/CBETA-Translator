# Phase 1 Foundation Report — Linux SSH Git Auth

## 1. Executive Summary

Phase 1 confirms that the product has one real integrated Git surface today: [`Views/GitTabView.axaml`](./Views/GitTabView.axaml) and [`Views/GitTabView.axaml.cs`](./Views/GitTabView.axaml.cs). Within that surface, the code already separates some transport-only actions from GitHub-auth actions structurally, but the user experience still blurs them in important places. Pure local Git actions exist and do not currently require GitHub sign-in. The two integrated PR workflows are mixed-capability flows that require GitHub API auth, call GitHub APIs directly, and also rewrite remotes to hardcoded HTTPS URLs before pushing.

Repository evidence also shows that SSH-compatible remotes are only partially tolerated today. Existing repo actions such as fetch/update can operate against whatever remote is already configured because they call local `git` without protocol filtering, but clone is hardcoded to an HTTPS GitHub URL, and both PR workflows force `origin` or `fork` to HTTPS. That means SSH remotes are effectively transformed away in the most GitHub-integrated workflows.

Phase 1 therefore establishes that the key product issue is not merely "add SSH somewhere" but "remove forced HTTPS transport from the normal contribution path." If the target fix is that Linux users can complete the existing integrated contribution workflow without Git Credential Manager, then the two PR workflows are in scope, not deferred: they must preserve or construct SSH-compatible fork remotes for transport while continuing to use separate GitHub API auth for fork and PR operations. Remaining blockers are now narrower and more concrete: confirm the exact transport behavior expected in the combined `Push + Create PR` workflow, carry those decisions into implementation planning, and complete the remaining negative-case Linux SSH validation for unsupported prompt-dependent failures. Positive manual evidence now confirms that a non-interactive-ready Linux SSH environment can satisfy the proposed initial-release support contract.

## 2. Current Integrated Git Action Matrix

| Action | Entry Point / Surface | Current Dependencies | Classification (`transport-only`, `GitHub-API-dependent`, `mixed-capability`) | Evidence | Notes / Ambiguities |
|---|---|---|---|---|---|
| Clone repository (`Get Files` when repo missing) | Git tab `BtnGetFiles` | Local `git clone`; hardcoded `RepoUrl` HTTPS | `transport-only` | [`Views/GitTabView.axaml.cs:338`](./Views/GitTabView.axaml.cs#L338), [`Views/GitTabView.axaml.cs:453`](./Views/GitTabView.axaml.cs#L453), [`Views/GitTabView.axaml.cs:23`](./Views/GitTabView.axaml.cs#L23), [`Services/GitRepoService.cs:44`](./Services/GitRepoService.cs#L44) | Transport-only in capability terms, but not SSH-capable today because the remote is fixed to `https://github.com/...git`. |
| Safe update (`Get Files` on existing repo / `Update (Keep My Local Changes)`) | Git tab `BtnGetFiles`, `BtnUpdateKeepLocal` | Local `git fetch`, `reset --hard`, backup/restore, branch safety helpers | `transport-only` | [`Views/GitTabView.axaml.cs:371`](./Views/GitTabView.axaml.cs#L371), [`Views/GitTabView.axaml.cs:423`](./Views/GitTabView.axaml.cs#L423), [`Services/GitRepoService.cs:51`](./Services/GitRepoService.cs#L51), [`Services/GitRepoService.cs:221`](./Services/GitRepoService.cs#L221) | Uses existing repo remotes with no GitHub API calls. Assumes `origin/main`. |
| Dangerous update (`Update (Discard Local Changes)`) | Git tab `BtnUpdateDiscardLocal` | Local `git fetch`, `reset --hard`, `clean -fd`, confirmation dialog | `transport-only` | [`Views/GitTabView.axaml.cs:409`](./Views/GitTabView.axaml.cs#L409), [`Views/GitTabView.axaml.cs:602`](./Views/GitTabView.axaml.cs#L602), [`Services/GitRepoService.cs:229`](./Services/GitRepoService.cs#L229) | Same remote assumptions as safe update. |
| Panic cleanup (`Don't Panic`) | Git tab `BtnPanic` | Local `git stash push -u`, `git stash drop` | `transport-only` | [`Views/GitTabView.axaml:119`](./Views/GitTabView.axaml#L119), [`Views/GitTabView.axaml.cs:665`](./Views/GitTabView.axaml.cs#L665) | No transport or GitHub API dependency once repo exists; included because it is an integrated Git action. |
| Create local single-file contribution commit | Git tab `BtnSendContribution` | Local status/add/stash/branch/commit/switch/stash-pop; translated-file preparation callback | `transport-only` | [`Views/GitTabView.axaml:115`](./Views/GitTabView.axaml#L115), [`Views/GitTabView.axaml.cs:941`](./Views/GitTabView.axaml.cs#L941), [`Views/MainWindow.axaml.cs:460`](./Views/MainWindow.axaml.cs#L460) | The UI explicitly sequences GitHub auth after this step, so current code treats it as local-only. |
| Authorize GitHub | Git tab `BtnAuth` | GitHub device-flow OAuth, `GET /user` | `GitHub-API-dependent` | [`Views/GitTabView.axaml:116`](./Views/GitTabView.axaml#L116), [`Views/GitTabView.axaml.cs:1116`](./Views/GitTabView.axaml.cs#L1116), [`Services/GitHubAuthService.cs:54`](./Services/GitHubAuthService.cs#L54), [`Services/GitHubApiService.cs:70`](./Services/GitHubApiService.cs#L70) | Pure API auth acquisition; no Git transport work. |
| Push single-file branch and create PR | Git tab `BtnPushPr` | GitHub auth, GitHub user lookup, fork detection/creation/wait, remote rewrite, local `git push`, GitHub PR creation | `mixed-capability` | [`Views/GitTabView.axaml:117`](./Views/GitTabView.axaml#L117), [`Views/GitTabView.axaml.cs:1165`](./Views/GitTabView.axaml.cs#L1165), [`Views/GitTabView.axaml.cs:1197`](./Views/GitTabView.axaml.cs#L1197), [`Views/GitTabView.axaml.cs:1240`](./Views/GitTabView.axaml.cs#L1240), [`Views/GitTabView.axaml.cs:1268`](./Views/GitTabView.axaml.cs#L1268), [`Views/GitTabView.axaml.cs:1288`](./Views/GitTabView.axaml.cs#L1288), [`Views/GitTabView.axaml.cs:1308`](./Views/GitTabView.axaml.cs#L1308) | Mixed by design and currently HTTPS-oriented. The combined button prevents transport-only push from being used independently. |
| Create local community-data commit | Git tab `BtnSendCommunityData` | Local file prep plus status/add/stash/branch/commit/switch/stash-pop | `transport-only` | [`Views/GitTabView.axaml:143`](./Views/GitTabView.axaml#L143), [`Views/GitTabView.axaml.cs:1553`](./Views/GitTabView.axaml.cs#L1553) | Same local-only pattern as single-file commit flow. |
| Push community-data branch and create PR | Git tab `BtnPushCommunityPr` | GitHub auth, fork detection/creation/wait, remote rewrite, local `git push`, GitHub PR creation | `mixed-capability` | [`Views/GitTabView.axaml:147`](./Views/GitTabView.axaml#L147), [`Views/GitTabView.axaml:149`](./Views/GitTabView.axaml#L149), [`Views/GitTabView.axaml.cs:1715`](./Views/GitTabView.axaml.cs#L1715), [`Views/GitTabView.axaml.cs:1743`](./Views/GitTabView.axaml.cs#L1743), [`Views/GitTabView.axaml.cs:1784`](./Views/GitTabView.axaml.cs#L1784), [`Views/GitTabView.axaml.cs:1808`](./Views/GitTabView.axaml.cs#L1808), [`Views/GitTabView.axaml.cs:1837`](./Views/GitTabView.axaml.cs#L1837) | Same mixed pattern as the translation PR flow. |
| Fetch and merge community data | Git tab `BtnFetchMergeCommunity` | Local `git fetch`, `git show origin/main:file`, local file merge service | `transport-only` | [`Views/GitTabView.axaml:151`](./Views/GitTabView.axaml#L151), [`Views/GitTabView.axaml.cs:1881`](./Views/GitTabView.axaml.cs#L1881), [`Views/GitTabView.axaml.cs:1912`](./Views/GitTabView.axaml.cs#L1912) | Transport-only, but hardcoded to `origin/main` and the two community-data paths. |

No standalone integrated `pull` action was found in the repository. The product's "update" behaviors are implemented as fetch plus reset/restore flows rather than `git pull`; evidence appears in [`Views/GitTabView.axaml.cs:377`](./Views/GitTabView.axaml.cs#L377), [`Views/GitTabView.axaml.cs:545`](./Views/GitTabView.axaml.cs#L545), and [`Views/GitTabView.axaml.cs:602`](./Views/GitTabView.axaml.cs#L602).

## 3. Remote and Protocol Handling Findings

### Confirmed findings

1. Existing-repo transport actions accept whatever remote is already configured.
Evidence: [`FetchAsync`](./Services/GitRepoService.cs#L51) runs `git fetch --all --prune` with no protocol checks, and update/community-merge flows call it directly from [`Views/GitTabView.axaml.cs:377`](./Views/GitTabView.axaml.cs#L377) and [`Views/GitTabView.axaml.cs:1913`](./Views/GitTabView.axaml.cs#L1913).
Why it matters: an already-cloned repository with an SSH `origin` can plausibly work for fetch-based actions, provided the local SSH environment is already non-interactively usable.

2. Clone is not protocol-neutral; it is hardcoded to an HTTPS GitHub URL.
Evidence: `RepoUrl` is fixed to `https://github.com/Fabulu/CbetaZenTexts.git` at [`Views/GitTabView.axaml.cs:23`](./Views/GitTabView.axaml.cs#L23), and clone uses that value at [`Views/GitTabView.axaml.cs:454`](./Views/GitTabView.axaml.cs#L454).
Why it matters: the integrated clone path does not currently allow SSH remotes at all, so Linux SSH support cannot claim clone coverage without changing scope or behavior.

3. Both PR workflows explicitly rewrite remotes to HTTPS before push.
Evidence: translation PR flow sets `remoteUrlClean` to `RepoUrl` or `https://github.com/{login}/{UpstreamRepo}.git` at [`Views/GitTabView.axaml.cs:1231`](./Views/GitTabView.axaml.cs#L1231) and [`Views/GitTabView.axaml.cs:1262`](./Views/GitTabView.axaml.cs#L1262), then applies it through [`EnsureRemoteUrlAsync`](./Services/GitRepoService.cs#L336). Community PR flow repeats the same at [`Views/GitTabView.axaml.cs:1776`](./Views/GitTabView.axaml.cs#L1776) and [`Views/GitTabView.axaml.cs:1804`](./Views/GitTabView.axaml.cs#L1804).
Why it matters: SSH remotes are not preserved in those workflows; they are implicitly transformed into HTTPS remotes.

4. Remote handling assumes `origin/main` in multiple update and merge paths.
Evidence: ahead/behind is measured against `origin/main` at [`Views/GitTabView.axaml.cs:387`](./Views/GitTabView.axaml.cs#L387); reset uses `origin/main` in update flows at [`Views/GitTabView.axaml.cs:545`](./Views/GitTabView.axaml.cs#L545) and [`Views/GitTabView.axaml.cs:602`](./Views/GitTabView.axaml.cs#L602); community merge reads `origin/main:{path}` at [`Views/GitTabView.axaml.cs:1919`](./Views/GitTabView.axaml.cs#L1919).
Why it matters: transport protocol is flexible there, but remote/branch naming is not fully generalized.

5. Git execution is intentionally non-interactive.
Evidence: every git command is launched with `GIT_TERMINAL_PROMPT=0` in [`Services/GitRepoService.cs:380`](./Services/GitRepoService.cs#L380).
Why it matters: HTTPS username/password prompts and SSH passphrase/password prompts should not work interactively inside the app. SSH can only succeed if the environment is already prepared, such as agent-backed keys and known-host trust already in place.

### Manual Linux validation update

Manual Linux validation now adds two planning-relevant data points.

1. A positive Linux SSH case has been validated outside the app in a non-interactive-ready environment.
Evidence: `ssh -T git@github.com` succeeded, and `GIT_TERMINAL_PROMPT=0 git ls-remote git@github.com:nmetrock/CbetaZenTexts.git` also succeeded without interactive prompting.
Why it matters: this directly supports the proposed initial-release support contract for Linux SSH in environments where host trust is already established and SSH authentication is already working, and it confirms that Git Credential Manager is not inherently required for the supported positive case.

2. The current integrated `Push + Create PR` failure on Linux is specifically a forced-HTTPS failure, not evidence against Linux SSH capability in a ready environment.
Evidence: the workflow prepared an HTTPS fork remote (`https://github.com/nmetrock/CbetaZenTexts.git`) and then failed during non-interactive push with `fatal: could not read Username for 'https://github.com': terminal prompts disabled`.
Why it matters: this strengthens the existing conclusion that the defect sits in the mixed PR workflow's forced-HTTPS behavior rather than in the basic viability of Linux SSH transport.

### Practical implication

Net conclusion: the repository already contains a usable separation between local Git work and GitHub API work, but remote handling is inconsistent and HTTPS-biased in exactly the workflows that matter for normal contribution. Existing SSH remotes can survive in transport-only fetch/update flows, yet clone and both PR workflows currently force HTTPS and therefore prevent Linux SSH from serving as the transport layer for the integrated contribution path. Manual Linux validation now strengthens that conclusion by adding one confirmed positive SSH case and one in-app forced-HTTPS failure case; the remaining direct validation gap is an unsupported prompt-dependent SSH failure observed on an SSH-targeted path.

## 4. Auth Coupling Findings

### Structural separation already present in code

Transport-only flows call `_git` service methods and never reference `_auth` or `_api`.
Evidence examples:
- Safe update path in [`Views/GitTabView.axaml.cs:423`](./Views/GitTabView.axaml.cs#L423)
- Commit creation path in [`Views/GitTabView.axaml.cs:941`](./Views/GitTabView.axaml.cs#L941)
- Community merge path in [`Views/GitTabView.axaml.cs:1881`](./Views/GitTabView.axaml.cs#L1881)

GitHub-API-dependent flows explicitly call `_auth` and/or `_api`.
Evidence examples:
- GitHub auth in [`Views/GitTabView.axaml.cs:1116`](./Views/GitTabView.axaml.cs#L1116)
- Translation PR flow in [`Views/GitTabView.axaml.cs:1197`](./Views/GitTabView.axaml.cs#L1197), [`Views/GitTabView.axaml.cs:1240`](./Views/GitTabView.axaml.cs#L1240)
- Community PR flow in [`Views/GitTabView.axaml.cs:1743`](./Views/GitTabView.axaml.cs#L1743), [`Views/GitTabView.axaml.cs:1784`](./Views/GitTabView.axaml.cs#L1784)

### Remaining coupling that affects product behavior

1. The mixed PR flows conflate transport auth and GitHub API auth into one UX action.
The code performs: verify OAuth token → inspect/create fork via API → rewrite remote URL → perform local `git push` → create PR via API.
Why it matters: a transport failure during `git push` occurs inside a workflow that the UI frames as "authorized GitHub upload," which can mislead both users and implementation planning into treating GitHub API auth as a substitute for Git transport credentials.

2. The current UX model treats GitHub sign-in as the gateway into "upload" workflows rather than as a capability used only for API-backed portions.
Evidence: the button sequence and tooltips are step-based, not capability-based, and the PR buttons are single combined actions. This matches the design document's concern that transport and API auth are too closely coupled.

3. There is no user-visible state for "Git transport ready, GitHub API unavailable" or the inverse.
Evidence: no separate capability panel or state model exists in the current Git tab; only per-action progress text and the shared log are used.

## 5. Initial Release Scope Recommendation

Recommended initial Linux SSH scope: support Linux "normal contribution" end-to-end in the existing Git-tab workflow, including the integrated PR paths, by preserving the current user-facing sequence while removing the forced HTTPS transport assumption from the push stage.

Explicitly supported workflows:

- Existing repo safe update and discard update.
- Existing repo fetch-based community merge.
- Local single-file commit creation.
- Local single-file branch push as part of `Push + Create PR`.
- Single-file PR creation after separate GitHub API auth.
- Local community-data commit creation.
- Community-data branch push as part of `Push + PR (Community Data)`.
- Community-data PR creation after separate GitHub API auth.
- Existing-repo panic cleanup.

Explicitly unsupported or deferred workflows:

- Integrated clone from the Git tab.
- Any SSH path that depends on interactive host-key acceptance or an interactive password/prompt inside the app.

Rationale for the proposed initial boundary:

- The product goal is normal contribution without GCM, and the current normal contribution path includes the combined PR workflows rather than transport-only actions in isolation.
- Clone is hardcoded to HTTPS today, so claiming SSH clone support would require expanding scope beyond the current Phase 1 evidence.
- Both PR workflows are mixed-capability and currently force HTTPS remotes, which is the exact behavior that breaks Linux contribution without a credential helper and therefore must be corrected for the target fix.
- The existing button sequence can remain intact from the user's perspective, but the internal behavior must separate transport push from GitHub API operations so that SSH transport and GitHub device auth are not conflated.
- Deferring clone remains reasonable because it is a separate HTTPS-only onboarding path; deferring the PR workflows would leave the main contribution path broken and would fail the stated feature outcome.

Dependencies that must be satisfied before implementation planning:

- Product decision: confirm that the initial implementation target includes both integrated PR workflows as part of "normal contribution."
- Product decision: preserve the existing visible workflow shape while allowing the push stage of `Push + Create PR` to use SSH-compatible remotes instead of forcing HTTPS.
- Product decision: whether clone is deferred entirely or must gain SSH-capable remote selection in the first release.
- Manual Linux validation input covering at least: one positive non-interactive-ready SSH case and one negative case where SSH transport fails because required trust or credentials are not already in place. (This dependency is now partially satisfied: the positive non-interactive-ready SSH case is supported by manual evidence, while the negative unsupported SSH case remains open.)

## 6. Resolved Proposal Unknowns

- [x] **Resolved**: Which exact integrated actions are currently transport-only versus GitHub-API-dependent?
Conclusion: the current Git tab has seven meaningful transport-only actions, one GitHub-API-only action (`Authorize GitHub`), and two mixed-capability PR workflows.
Supporting evidence: Section 2 action matrix; UI entry points at [`Views/GitTabView.axaml:115`](./Views/GitTabView.axaml#L115) and [`Views/GitTabView.axaml:143`](./Views/GitTabView.axaml#L143).
Remaining uncertainty: none at the Git-tab level. No second integrated Git surface was found elsewhere in the repo.

- [x] **Resolved**: Does the current product treat clone the same way as fetch/pull/push for auth and remote handling, or is clone a special case? `[NEEDS CLARIFICATION]`
Conclusion: clone is a special case. It is handled in the same Git-tab surface, but it always uses the hardcoded HTTPS `RepoUrl` and does not inspect or preserve an existing remote.
Supporting evidence: [`Views/GitTabView.axaml.cs:23`](./Views/GitTabView.axaml.cs#L23), [`Views/GitTabView.axaml.cs:453`](./Views/GitTabView.axaml.cs#L453).
Remaining uncertainty: none about current behavior.

- [x] **Resolved**: Are any current fork or repository-detection paths dependent on GitHub APIs in places where the user expects transport-only behavior?
Conclusion: yes, but only inside the two PR workflows. Fork existence, fork creation, fork readiness, username lookup, and PR creation are all GitHub API calls there.
Supporting evidence: [`Views/GitTabView.axaml.cs:1197`](./Views/GitTabView.axaml.cs#L1197), [`Views/GitTabView.axaml.cs:1240`](./Views/GitTabView.axaml.cs#L1240), [`Views/GitTabView.axaml.cs:1308`](./Views/GitTabView.axaml.cs#L1308), [`Views/GitTabView.axaml.cs:1743`](./Views/GitTabView.axaml.cs#L1743), [`Views/GitTabView.axaml.cs:1784`](./Views/GitTabView.axaml.cs#L1784), [`Views/GitTabView.axaml.cs:1837`](./Views/GitTabView.axaml.cs#L1837).
Remaining uncertainty: none about the PR flows; no evidence of similar API dependence in update/commit/merge flows.

- [x] **Resolved**: Should the initial implementation support all SSH-compatible integrated Git workflows at once, or should a narrower first release be accepted if the unsupported workflows are explicitly identified?
Conclusion: the target fix requires including the integrated PR workflows in scope for the initial implementation, while clone may still be deferred as a separate HTTPS-only onboarding path.
Supporting evidence: the PR workflows are part of the existing normal contribution path and they are the place where SSH-compatible remotes are currently rewritten to HTTPS.
Remaining uncertainty: none about the PR workflows being in scope; clone scope remains a product choice.

- [x] **Resolved**: Preserve the design boundary that Git transport auth and GitHub API auth are separate concerns.
Conclusion: the current code already has enough structural separation to preserve distinct transport and GitHub API capabilities, but the combined PR handlers currently violate that boundary by forcing HTTPS remotes and blending push and PR work into one opaque action stream.
Supporting evidence: transport-only flows do not call `_auth` / `_api`; PR flows do.
Remaining uncertainty: none about the current code split; implementation still needs explicit UX/state work later.

## 7. Remaining Constraint / Validation Gap

Most of the architectural and scope questions that originally blocked implementation planning have now been resolved in the design, proposal, and ADR set.

Resolved since this report’s initial drafting:
- Initial Linux SSH support includes the existing integrated PR workflows as part of the normal contribution path.
- Integrated PR workflows must not silently rewrite SSH-compatible push paths to forced HTTPS.
- SSH-capable PR paths must preserve existing SSH-compatible remotes where applicable and construct/select SSH-compatible fork remotes according to the approved policy.
- The combined PR actions remain in place for the first release, but their major transport and PR/API stages must be separately attributable in the Git-tab progress/state surface and log.
- Clone remains outside the initial Linux SSH contribution scope and continues as the existing HTTPS onboarding path.

The remaining open validation question is narrower:

- Confirm, with direct manual Linux evidence, the negative prompt-dependent / first-use SSH cases required to fully close the proposed non-interactive SSH support contract for the initial release.

This does not block child-capability planning from proceeding under the current approved boundary. It remains a validation and ADR-002 closure dependency.

## 8. Adopted Planning Baseline

The following decisions now define the implementation-planning baseline for this feature:

- Initial Linux SSH support includes the existing integrated PR workflows because they are part of the normal contribution path.
- Integrated PR workflows must stop rewriting SSH-compatible remotes to HTTPS during the push stage.
- Existing SSH-compatible remotes must be preserved where applicable, and newly created/selected fork remotes must follow the approved SSH-compatible fork policy.
- The product keeps the combined `Push + Create PR` and `Push + PR (Community Data)` actions in the first release, while treating transport push and GitHub PR creation as separately attributable internal stages.
- The initial Linux SSH support contract is non-interactive-ready SSH only: trusted-host state and other SSH readiness must already be satisfied; prompt-dependent SSH cases remain unsupported and must classify as transport/environment issues.
- Clone remains the existing HTTPS-only onboarding path for the initial release and is not part of the first Linux SSH contribution scope.

Residual caveat:
- The non-interactive SSH support contract remains pending final empirical closure until negative prompt-dependent SSH validation is completed and ADR-002 is formally closed.

## 9. Appendix: Repository Evidence

- Git UI surface: [`Views/GitTabView.axaml`](./Views/GitTabView.axaml), [`Views/GitTabView.axaml.cs`](./Views/GitTabView.axaml.cs)
- Git transport service: [`Services/GitRepoService.cs`](./Services/GitRepoService.cs), [`Services/IGitRepoService.cs`](./Services/IGitRepoService.cs)
- GitHub auth service: [`Services/GitHubAuthService.cs`](./Services/GitHubAuthService.cs)
- GitHub API service: [`Services/GitHubApiService.cs`](./Services/GitHubApiService.cs)
- Main-window integration back into repo loading/state refresh: [`Views/MainWindow.axaml.cs:465`](./Views/MainWindow.axaml.cs#L465)
- Current user-facing Git/GitHub guidance, including Linux credential-manager advice: [`README.md:187`](./README.md#L187)
- Phase 1 scope source: [`01-linux-ssh-git-auth.md`](./01-linux-ssh-git-auth.md)
- Design boundary source: [`linux-ssh-git-auth-design.md`](./linux-ssh-git-auth-design.md)
