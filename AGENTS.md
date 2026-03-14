# AGENTS.md

## Scope
These instructions apply to the entire repository tree unless overridden by a deeper `AGENTS.md`.

## Current Project Instructions
- Follow direct user requests first.
- Keep code changes minimal, focused, and easy to review.
- Avoid unrelated refactors.
- Prefer validating changes with targeted checks when possible.

## Notes
### Trinity / B200 Run Guardrails
- Treat multi-dataset training as a mixed-DoF setup (Aloha 14-DoF + SO100 6-DoF).
- Keep DoF padding and mask semantics consistent: valid joints = `1`, padded joints = `0`.
- If `smolvla` is the active training policy, ensure joint-level `action_mask` is applied in loss reduction.
- Do not remove or bypass mask-aware loss logic in `smolvla` without explicit approval.
- Preserve compatibility when masks are missing (fallback behavior should remain valid).

### Pre-Run Consistency Checks
- Keep docs and run configs consistent on model size, policy type, and compute plan before launch.
- Verify dataset blending assumptions (sampling weights, camera mapping, DoF alignment) match code paths.
- Prefer targeted validation before major runs:
  - compile check for edited Python files
  - focused policy/processor tests when available
  - one dry-run batch/forward check if environment permits

### Change Scope
- For launch-critical work, prioritize correctness over broad refactors.
- Keep changes local to the training path in use (avoid touching unrelated policies or runtime code).
