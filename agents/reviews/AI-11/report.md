<!-- Provenance: saved verbatim by the orchestrator (cycle 2026-11-08 12:00Z) from the qa-reviewer PR comment https://github.com/MaheshPulivarthi18/ArxivLens/pull/38#issuecomment-6721515684, because the QA harness could not write report.md. -->

[qa-reviewer] QA report: AI-11 · PR #38 · round 1

**Verdict:** PASS
**Reviewed commit:** `0085feedd08b4358686f12a996e7676f1f6f8961` · **Date:** 2026-11-08
**Ticket:** [agents/tasks/AI-11.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/agents/tasks/AI-11.md) · **PRD:** Product PRD ING-3, QA-3, §7 principle 3; Technical PRD §6.2; ADR-0014 · **Design:** [docs/design/ING-11.md](https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/main/docs/design/ING-11.md) decision 1 + PM condition 1

Evidence folder: https://github.com/MaheshPulivarthi18/arxivlens-agents/tree/f7ba64a5fce03b6984ae8528fc17f8f3648377da/agents/reviews/AI-11/evidence
(The harness refused to let the QA subagent write `agents/reviews/AI-11/report.md`, so this comment is the report. The orchestrator saves it verbatim.)

## Test results
| Check | Source | Result |
|---|---|---|
| Go (vet, gofmt, test, build) | CI 128726083149 | pass ([00](``https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f7ba64a5fce03b6984ae8528fc17f8f3648377da/agents/reviews/AI-11/evidence/00-ci-checks.png?raw=true))`` |
| Python M0 unit tests | CI 128726083334 (merge of `0085fee` into current main `9651294`) | pass: `126 passed, 1 skipped` vs main 128680958751 `114 passed, 1 skipped`, so +12 = the 12 new tests. The skip is dot 59 of 127, and `test_processor_pages.py` (20 tests, last file) is dots 108-127, all passing ([01](```https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f7ba64a5fce03b6984ae8528fc17f8f3648377da/agents/reviews/AI-11/evidence/01-ci-python-job.png?raw=true))``` |
| Frontend (lint, test, build) | CI | pass |
| DB / Full stack | CI | pass |
| Agent ownership check | CI 128726083458 | `Ownership OK for role=ai (216 changed lines)` ([02](````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f7ba64a5fce03b6984ae8528fc17f8f3648377da/agents/reviews/AI-11/evidence/02-ac2-ac4-diff-scope.png?raw=true))```` |
| `make test-unit` / `pytest tests/test_processor_pages.py` | local | **not run locally with real deps**: no transformers/PyMuPDF/torch, PyPI and huggingface.co are blocked, no Go 1.25. CI is the record (01) |
| PR's non-PDF tests (AC3 a-g) | local, **stand-in** word-level fast tokenizer + MagicMock pymupdf/torch/worker | 10/10 pass ([03](`````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f7ba64a5fce03b6984ae8528fc17f8f3648377da/agents/reviews/AI-11/evidence/03-ac3-standin-pr-tests.png?raw=true))````` |
| QA random probe: head vs `origin/main` chunker + independent page oracle | local, stand-in | 400 docs, 12389 chunks, 6468 with `page_start`, 1289 with breaks but unknown: 0 identity, 0 oracle and 0 unknown failures ([04](``````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f7ba64a5fce03b6984ae8528fc17f8f3648377da/agents/reviews/AI-11/evidence/04-qa-random-probe.png?raw=true))`````` |
| Mutation (18 single-edit mutants of the production lines) | local, stand-in | PR tests kill 15/18. The probe kills M03. M09/M18 change nothing for real HF tokenizers or worker output ([05](```````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f7ba64a5fce03b6984ae8528fc17f8f3648377da/agents/reviews/AI-11/evidence/05-mutants.png?raw=true```````)) |
| `make lint` | CI | pass (Go + frontend only; no Python linter in `make lint`). Extra: ruff E/F/W finds 17 issues, all on pre-existing lines, none on added lines ([08](````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f7ba64a5fce03b6984ae8528fc17f8f3648377da/agents/reviews/AI-11/evidence/08-ruff-preexisting-only.png?raw=true))```````` |
| `make eval` | not run | Chunk text is byte-identical: the AC2 snapshot passes in CI (01), and the probe (04) shows 0 identity failures vs `origin/main` on 400 random docs. Accepted |

## Acceptance criteria
| AC | Met? | Evidence |
|---|---|---|
| AC1 | ✅ | `test_chunk_page_start_matches_first_word_page` (tests/test_processor_pages.py:254). It runs the production `ProcessorWorker._parse_doc_sections(None, doc)` and `TokenChunker(MODEL_NAME)`, then checks that every chunk has `page_start` (:248), that it is `>= 1` (:249), that it equals `first_word_page(body)` (:251), and that `any(page_start > section page)` (:259) ([07](`````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f7ba64a5fce03b6984ae8528fc17f8f3648377da/agents/reviews/AI-11/evidence/07-ac1-ac5-test-asserts.png?raw=true)).````````` It passes in CI with real BGE + PyMuPDF (01) |
| AC2 | ✅ | The diff is append-only: 0 deleted lines, a single hunk at :212, and base lines 1-213 are byte-identical in the head (02), so `test_chunk_output_identical_to_pre_change`, `EXPECTED_SNAPSHOT` and `build_fixture_doc` are unmodified. `tests/test_m0.py` has an empty diff (02). Both pass in CI (01: no failures in the run). `make eval` is "not run: chunk text identical", backed by 01 and 04 |
| AC3 | ✅ | `test_page_start_hand_made_sections` (a, b, c, c-break-inside-first-word, d, first-break-after-start) and `test_page_start_absent_when_unknown` (e: no-key and empty-list; f: is_fast-false and call-ids-differ). (g) is asserted in every row. They pass in CI with the real BGE tokenizer (01) and locally on the stand-in (03). The ids-compare, is_fast, `bisect_right`, `>=` first-break, start-offset, `lead`-missing and default-page mutants are all killed (05). The double-counted `lead` mutant survives: see finding 1 |
| AC5 | ✅ | `build_fixture_doc_ac5` is a new module-level builder (02: the old builder is unmodified). `test_chunk_page_start_abstract_bucket_and_heading_at_page_end` asserts sections `[("Abstract",1),("Introduction",1)]`, Abstract `page_breaks == [(0,1)]`, Intro `page_breaks[0] == (0,2)`, oracle page on every chunk with `>= 1`, both sections emitted, and `intro[0]` `page_start == 2` with `page_number == 1` (07). It passes in CI (01) |
| AC4 | ✅ | +216/−0 (< 400). CI ownership check OK for role=ai. Only `scripts/m0_skeleton.py` and `tests/test_processor_pages.py` change, and no open PR (#24, #35, #37) touches either file (02) |

## Scope and design check
- Changed files: `scripts/m0_skeleton.py` (+16) and `tests/test_processor_pages.py` (+200). Both are ai-owned, and nothing touches `services/`, `PaperParser` or `tests/test_m0.py`. No ticket, review or doc files leaked into the PR.
- Design decision 1 + PM condition 1, checked line by line:
  - `tokens = self.tokenizer.encode(sec_text, add_special_tokens=False)` is unchanged and still drives windowing.
  - The second `self.tokenizer(sec_text, add_special_tokens=False, return_offsets_mapping=True)` call happens only when `page_breaks` is non-empty and `is_fast` is true.
  - An ids mismatch means the whole section is unknown, with no exception.
  - `lead` is computed from the raw text, and the code uses `bisect_right - 1` and `char >= page_breaks[0][0]`.
  - There is no default page. The key is set after the chunk dict is built, so every other field is untouched.
  - No deviation from the design.

## PRD fit
This gives the chunker an exact, fail-safe "page the chunk's text starts on", which ADR-0014's `page` ("only returned when the chunker recorded it") and §7 principle 3 (one click to the source, via ING-11b → AI-8 → FE-4) need. When the page can't be known, the key is left out and never guessed, which matches the honest-refusal principle. Retrieval inputs are unchanged.

## Findings
1. [nit] **AC3(d) pins `lead` from below only.** Mutant M03 takes the offsets from the raw (unstripped) text, so `lead` is added twice. It passes all 10 PR non-PDF rows, because `d-leading-ws` puts its break exactly at chunk 1's first char, and a chunk that is `len(LEAD)` chars "late" still lands on the right side of it. Demo ([06](``````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f7ba64a5fce03b6984ae8528fc17f8f3648377da/agents/reviews/AI-11/evidence/06-m03-double-lead.png?raw=true)):`````````` with the break at chunk1_char+1 or +3, head gives page 1 (correct) and M03 gives 2. The random probe kills M03 (05: 35 oracle failures). Not blocking: the head is correct (04), and the worker never produces leading whitespace (`line_text` is stripped and is the only text write, 07), so `lead == 0` in production today. Suggested fix: add a `d` row with the break at `len(LEAD) + chunk_char(base[1]) + 1`, expecting chunk 1 to stay on page 1.
2. [spec] The ticket's verification lists `make lint`, but `make lint` is `lint-go lint-fe` and has no Python linter, so for a Python-only PR it checks nothing. The extra ruff run (08) shows no new issues. pm-lead may want a follow-up (backend: a ruff target for `scripts/`, `services/` and `tests/`) or to drop `make lint` from Python-only tickets' verification.

## Missing tests
- AC3(d) row with a break 1..`len(LEAD)-1` chars after a chunk start (finding 1).
- `page_breaks: None` (M18): the code handles it (`or []`), but no test pins it. The worker never emits `None`, so this is informational only.
- (Informational) No test uses a window that starts mid-word (a `##` continuation piece). The fixture vocabulary is single-wordpiece by design, so the offset of a continuation piece has only been exercised by reasoning: its offset falls inside the word, and breaks lie at line starts.

## Hand-off
PASS → pm-lead final review. Finding 1 is a [nit]: PM decides whether it rides along in this PR or becomes a follow-up.

## Provenance and limits
- Real BGE tokenizer, PyMuPDF fixtures (AC1, AC2, AC5) and the full test run: CI job logs only (01), fetched via `gh api .../actions/jobs/<id>/logs`. Job `head_sha` checked = `0085fee` (merge onto current main `9651294`).
- Everything marked "local" uses a QA **stand-in** word-level fast tokenizer with exact offsets, not BGE. Its full source is rendered in [09](```````````https://github.com/MaheshPulivarthi18/arxivlens-agents/blob/f7ba64a5fce03b6984ae8528fc17f8f3648377da/agents/reviews/AI-11/evidence/09-harness-source.png?raw=true)``````````` for re-review control runs. Mutants were made only in `mktemp` copies. Nothing was pushed to ArxivLens.


---
_Generated by [Claude Code](https://claude.ai/code)_

## PM verdict

**Verdict:** APPROVE · **Reviewer:** pm-lead · **Date:** 2026-11-08 · **Reviewed commit:** `0085feedd08b4358686f12a996e7676f1f6f8961` (QA PASS r1, evidence pack @ `f7ba64a`)

**What I checked**
- Ticket, ING-11 design decision 1 + PM condition 1, Product PRD ING-3 / QA-3 / §7 principle 3, Technical PRD §6.2, ADR-0014 (`page` "only returned when the chunker recorded it").
- The production diff myself (`scripts/m0_skeleton.py` +16/−0): `encode` still drives windowing; the second offsets call runs only for a non-empty `page_breaks` and `is_fast`; an ids mismatch leaves the whole section unknown without raising; `lead`, `bisect_right - 1`, `>= page_breaks[0][0]`, no default page; the key is added after the chunk dict is built. Matches condition 1 line for line.
- Dependency: ING-11 (#33) merged 2026-11-08T06:00Z, and CI merged the head onto main `9651294`, which contains it.
- All ten evidence files (00-09, PNG and the `.txt` where the PNG is cut). Each PNG shows the result for its AC: 00 (6/6 checks green on `0085fee`), 01 (CI python job: `126 passed, 1 skipped` vs main `114 passed, 1 skipped`, test_processor_pages.py in the command line, no failures, so AC1/AC2/AC3/AC5 ran with the real BGE tokenizer and PyMuPDF), 02 (append-only diff, lines 1-213 identical, `test_m0.py` untouched, ownership OK 216 lines, no open-PR overlap), 03 (10 non-PDF rows, stand-in tokenizer, labelled as such), 04 (400-doc probe: 0 identity, 0 oracle, 0 unknown failures vs `origin/main`), 05 (18 mutants), 06 (M03 demo), 07 (AC1/AC5 assertions + worker text writes), 08 (ruff: no findings on added lines), 09 (harness source).
- I also read `services/processor/worker.py` on `origin/main`: empty lines are skipped (`if not line_text: continue`) and every write is a stripped `line_text + " "`, so section text never starts with whitespace and `lead == 0` in production today.

**PRD / scope fit.** It delivers what the ticket intended and nothing more: the chunker is the only place that knows where a window starts, it records the start page exactly or not at all (honest "unknown", never a guess), and chunk text, hashes and every other field are byte-identical, so retrieval and embeddings can't move. This is the producer step of §7 principle 3 (one click to the source); users see nothing until ING-11b → AI-8 → FE-4, so no PRD status column or README line changes with this PR (ING-3 and QA-3 are already ✅, and the page link has no row of its own yet). DoD 3: `make eval` not run, because chunk text is identical (AC2 snapshot green in CI, probe 04): accepted.

**Rulings on QA findings**
1. [nit] AC3(d) pins `lead` only from below (M03, double-counted `lead`, survives the PR tests): **follow-up, not blocking.** AC3(d) as written ("leading whitespace → still correct") is met, the head is correct on 400 random docs with random leads (04, which kills M03), and production text has `lead == 0` (checked above), so M03 could not change a stored page today. A rework round would cost a full QA + PM cycle for a regression guard on a path production doesn't take. Follow-up **AI-11f** (ai-engineer, P3, test-only, one table row): add a `d` row with the break at `len(LEAD) + chunk_char(base[1]) + 1`, expecting chunk 1 to stay on the earlier page; optionally a `page_breaks: None` row (M18). Fold it into the next ai PR that touches `tests/test_processor_pages.py`; it must land before anything makes section text start with whitespace.
2. [spec] `make lint` is `lint-go lint-fe`, so it checks nothing on a Python-only PR: **accepted as a spec fault, mine.** Follow-ups: (a) backend, P3: a Python lint target (ruff E/F/W, scoped to added lines or with the 17 pre-existing findings fixed first) wired into `make lint` and CI; (b) pm-lead *Proposed* rules PR: `agents/templates/task.md` Verification note "for Python-only tickets, `make lint` checks nothing until (a) lands; ask for `ruff check <files>` on added lines". Until then I drop `make lint` as Python evidence from my specs. Lesson recorded.

**Missing tests (informational, QA):** a window starting on a `##` continuation piece is covered only by reasoning; acceptable, because breaks sit at line starts and a continuation piece's offset is inside its word. No follow-up.

**Risk for Mahesh (in the PR body):** after this merges, real ingests start writing `paper_chunk_pages` rows (`services/common/db.py:126` writes one only when a chunk carries `page_start`, so until now it wrote none). Nothing reads them until ING-11b. Separately, #35 RET-2's `TestSearchProvenance` has been red since #33 merged (PROGRESS 2026-11-08 ~14:20): its page expectation has to be settled in RET-2 either way, and this PR doesn't touch that test.

PR raised: description rewritten with the Evidence section, marked ready for review. Merge is Mahesh's.
