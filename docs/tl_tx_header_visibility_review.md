# Transmit header visibility qualification

The candidate moves invalid-word masking from the two transmit Header FIFO outputs to the channel's final payload assembly. Qualification can inspect the retained header directly, while header eligibility and diagnostics still require the original valid flag. Existing public FIFO/storage and channel callers retain their original defaults. No port, register, cycle, logical queue capacity or Data-bank behavior is added or changed.

`upli_receive_fifo` and `upli_receive_storage` add `C_ZERO_INVALID`, default 1. Only the Header FIFO instances in `tl_tx_buffered` select 0. `tl_tx_channels` adds `RAW_HEADERS`, default 0; only that buffered composition selects 1. In this profile the selected invalid header and its atomic tags are zeroed at assembly, and invalid `has_data` is also zero. The latter is required even for arbitrary, inconsistent held states. Both parameters reject values other than 0 and 1 during elaboration.

## Verification boundary

The frozen RTL reference is `6839cac6a0e789fdef41787ae6da3e8546e896b2`. The channel proof compares its explicitly masked header/tag inputs with the candidate's raw inputs, retaining every public output and all eight actual next-state bits. No stall, validity, held-state or credit assumptions are introduced. WIDTH 8–16 all pass, with independent reset SAT on both sides. Existing standalone channel semantics also pass all nine widths against the older `1f917a1` reference.

The FIFO proof checks default and raw/remasked composition at data widths 8, 32 and 512, and depths 1, 2, 3, 5, 129 and 257: 36 complete-state configurations and 72 independent reset checks. It also checks that the actual raw profile exposes the retained `reg_head` bits. The buffered proof compares every real FF transition, public output and exposed SRAM transaction output against the frozen reference, with arbitrary common SRAM read data. It does not substitute internal control signals.

Two actual RTL faults remove invalid payload/tag masking or invalid `has_data` masking. Both are detected at WIDTH 8/16 by the same complete channel comparison. The initial missing-parameter elaboration is retained as the pre-implementation failure. A BLIF export initially duplicated shared macro-address aliases; the proof helper now runs Yosys alias cleanup after independently auditing the exact D/Q cut. The failed export is retained and is not counted as an equivalence result.

The first candidate triggered strict lint warnings because logical negation was applied to integer parameters. The isolated corrected candidate uses explicit equality to zero. Its 16 profile elaboration/lint checks pass, including rejection of signed −1 and 2. Yosys requires the two's-complement literal for −1; the initial command-parser rejection is retained separately from the successful RTL parameter rejection. Both corrected channel proof matrices, the 36 FIFO configurations and six buffered WIDTH 8/16, depth 1/2/3 configurations pass. Both corrected fault types are also detected at both widths.

## Measured candidate and pending adoption

The initial source candidate passes all 1,258 channel vectors, 36 production unit configurations / 5,760 modeled cycles, six actual SRAM FIFO depth runs, 32 actual production peer configurations, and their independent wire/queue/partition/capture audits. All 128 peer trace files are byte-identical to the qualification-reuse baseline. All 27 production ownership configurations pass 35 properties per configuration; normal and optimized Python audits agree. All 22 production-top wire faults, 16 channel unit fault instances and 64 channel peer fault instances are detected. The initial channel check stage remains failed because its lint warnings are real; successful fault detection does not override that failure.

The initial physical candidate retains 64 SRAM interfaces and 6,254 / 6,574 FFs. Its WIDTH 8 measurements complete at area 44,790.732 µm² and worst setup −1.806385 ns, versus 44,696.106 µm² and −1.853540 ns for the baseline. The actual worst path now starts at Response Header FIFO `reg_head[120]` and ends at Request Header FIFO `cnt_unread[1]`; the earlier cache-valid count is no longer its startpoint. WIDTH 16 and final corrected-source measurement/adoption are still being completed.

The lint-corrected sources are not yet adopted on the strength of the initial mappings. Final source identity, actual mapped correspondence and the complete physical audit remain required. All timing numbers use actual standard cells with synthetic SRAM timing, without layout parasitics; they are not characterized macro or full-IP signoff. The 640 ps target remains open.

## Reproduction

Run from the repository root with the authorized dependency root supplied explicitly:

```sh
python3 verification/tl_tx_qualification/run_header_visibility.py --label NEW_COMPOSITE
python3 verification/tl_tx_qualification/run_header_visibility.py --label NEW_PAYLOAD_FAULT --fault payload --widths 8 16
python3 verification/tl_tx_qualification/run_header_visibility.py --label NEW_DATA_FAULT --fault has_data --widths 8 16
python3 verification/tl_tx_qualification/run_storage_visibility.py --label NEW_FIFO --top fifo --depths 1 2 3 5 129 257
python3 verification/tl_tx_qualification/run_storage_visibility.py --label NEW_BUFFERED --top buffered --kd28-root "$KD28_ROOT" --widths 8 9 10 11 12 13 14 15 16 --depths 1 2 3
python3 verification/tl_tx_qualification/run_visibility_profiles.py --label NEW_PROFILES --kd28-root "$KD28_ROOT"
```

Each label creates immutable source snapshots, generated proof/elaboration scripts, logs and `results.json` under `build/verification/tl_tx_qualification`. An optional `--rtl-root` points to an isolated candidate tree. Follow with the production unit/peer/ownership, physical and mapped-correspondence commands in the existing qualification review. The full Endpoint/Switch, protocol/payload, digital PHY, INC, security, manageability and characterized macro obligations remain open.
