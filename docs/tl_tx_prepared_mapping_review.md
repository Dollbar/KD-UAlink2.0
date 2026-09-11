# Production transmit mapped correspondence checkpoint

The actual production netlists from `physical_baseline` are retained unchanged. The complete 60-case physical audit is recorded in [the timing review](tl_tx_prepared_timing_review.md). This checkpoint prepares a full-state correspondence proof; it does not establish mapped equivalence.

| WIDTH | Normalized RTL state bits | Actual mapped state bits | Common input bits including SRAM reads | Public and SRAM transaction output bits |
|---|---:|---:|---:|---:|
| 8 | 6,244 | 6,254 | 5,511 | 4,144 |
| 16 | 6,564 | 6,574 | 5,831 | 4,144 |

All original positive-edge FF D/Q equations are observed. The independent `audit_cut` checks every original combinational equation, original port and actual clock. Each of the 64 original SRAM instances is exposed at its real interface: read outputs become common arbitrary inputs, while clocks, controls, addresses, masks and write data remain compared outputs. The two full public/macro interfaces have identical names, directions and widths.

The state-count difference comes from the actual synthesis FSM recoding of both preparation cursors from four binary bits to nine one-hot bits. The mapping logs give the same codebook for both lanes and widths: binary states 0,8,4,2,6,1,5,3,7 correspond to one-hot bit positions 0 through 8. The strict identical-state check in `run_mapped_pair.py` correctly rejects the differing aliases. The complete D/Q artifacts emitted before this rejection are retained; `inventory_audit.json` records their separate structural audit.

`run_encoding_cec.py` consumes these exact artifacts and the real mapping-log codebooks. It reconciles all noncursor state bits and constants, compares all 4,144 public/macro output bits, and compares every actual mapped next-state bit under both binary cursors being in 0..8. Five tests, run under ordinary and optimized Python, check the actual codebooks and reject missing rows, duplicate one-hot codes, uncovered state and changed constants. Twenty existing complete-state checker tests also pass under both modes.

The first `encoded_step` run failed at BLIF read-in because new wrapper operators were not lowered to basic gates. Its original logs and runner snapshot are preserved. The corrected `encoded_step_techmapped` run includes `techmap`; all emitted graphs pass Yosys checks and contain no unresolved BLIF subcircuits or latches. CEC outcomes are recorded in its `results.json`. Both whole-network comparisons and the WIDTH 8 automatic partitioned comparison reach the 150-second external limit without a complete result. This is an unresolved proof, not a counterexample or a pass.

The partitioned diagnostic also reported four dangling dead aliases in the raw gold BLIF. A separate backwards-cone audit using the existing `prune_dead_names` helper proves that all public-output and next-state roots are fully driven, and emits `gold_pruned.blif`/`gate_pruned.blif` plus source-bound `dead_alias_audit.json` at both widths. These pruned artifacts have not yet been used for a completed proof; no result is transferred to them from the raw BLIF runs.

Run commands from the project root with fresh labels:

```sh
python3 verification/tl_tx_prepared/run_mapped_pair.py --label NEW_PAIR --widths 8 16
python3 verification/tl_tx_prepared/run_encoding_cec.py --pair NEW_PAIR --label NEW_CEC --widths 8 16
python3 verification/tl_tx_prepared/test_encoding_relation.py
python3 -O verification/tl_tx_prepared/test_encoding_relation.py
```

The relation tests use the retained `mapped_pair` and `physical_baseline` fixtures. Pair preparation currently exits 1 at strict alias matching after writing the audited D/Q artifacts; the encoding-aware stage exists to address that explicit difference. Results live under `build/verification/tl_tx_prepared/LABEL` and are excluded from Git together with restricted libraries and generated netlists.

Next complete an auditable partitioned proof on the preserved output/next-state cones, establish reset and independent dormant payload relations, and qualify actual mapped-cell faults. A same-state conditional CEC alone cannot establish post-reset sequential equivalence. Physical timing repair, full payload/Data-bank proof, final Endpoint/Switch integration and the rest of the dual-IP Goal remain open.
