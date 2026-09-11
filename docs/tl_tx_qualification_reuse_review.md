# Reuse selected transmit qualification

The transmit channel now reuses each class's existing qualification result when selecting and packing a Flit. The previous path selected a 256-bit header and decoded its format, tenure, credit and catch budget again. `tl_tx_packer_core` contains the original source arbitration, payload assembly and four state bits; `tl_tx_packer` retains its public interface and qualification logic. `tl_tx_channels` connects the already computed selected-lane ready, NOP-ready and raw has-data signals to the core. There is no added register or cycle of latency.

The raw has-data signal remains relevant while a selected header is held, even if the current readiness changes. The comparison therefore includes arbitrary input changes during stalls, rather than assuming those inputs remain consistent with the stored selection.

## RTL and integration evidence

The frozen reference is Git commit `1f917a1381277a080a700849d638d39b766c665a`. The current comparison runner reads its RTL directly from local Git objects, so the proof does not require a manually retained baseline build directory.

- Both standalone packer and integrated channels pass complete public-output and actual next-state CEC for WIDTH 8 through 16: 18 configurations, with four/eight actual state bits. All 36 independent reset SAT queries pass.
- An actual selected-ready wiring mutation is detected at WIDTH 8 and 16 through the same complete-output/next-state proof entry. The unchanged reset behavior of these mutants is checked independently.
- The actual packing core has four positive-edge state bits. Its source-control outputs and next-state cones do not depend on raw Header/Tag/Data/FC payload bits. The missing-core elaboration failure was retained before implementation.
- Independent packer/channel vectors pass 3,170 and 1,258 cycles. Lint and synthesis pass at both widths. Sixteen unit fault types produce 32 actual failing simulations; the corresponding peer fault matrices contain 32 packer and 64 channel detections.
- The production prepared-transmit unit passes 36 configurations across nine widths, Auth on/off and queue depths 1/3, totaling 5,760 modeled cycles. Its actual dual-peer regressions pass 32 configurations, including minimum Header/Data depth 1.
- Independent wire, queue, SRAM and capture audits pass under normal and optimized Python, producing byte-identical evidence. The two peer matrices total 28,868 cycles, 13,016 stored/consumed SRAM words and 7,712 FC transfers. All 22 production-top wire faults are detected.
- The authored wrapper/core static gate has zero errors and 20 style advisories for the repository's existing header, region and state-name conventions. This is separate from the passing external lint and simulation checks.
- A clean local clone with the candidate source overlay passes `make test rtl-smoke prepared-tx-smoke KD28_ROOT=PATH`. The new channel equivalence entry also passes from that clone without a baseline build directory. Default skill report placement remains compatible with the existing auditor.

The production ownership rerun passes all 27 configurations and 35 properties per configuration. Independent auditing verifies the exact SRAM abstraction, actual state, induction base/step logs and six real wiring counterexamples; ordinary and optimized Python results are identical. No new reachability cover run is claimed. Current physical/mapped results are recorded in `docs/status.json`. Prior physical correspondence applies to the frozen reference commit; it does not establish the candidate's newly synthesized gates.

## Actual process measurements

The same TSMC 28HPC+ standard-cell libraries, five corners, three synthetic SRAM views, two clock periods and original IO/clock budgets produce all 60 measurements. Normal and optimized Python physical audits agree byte for byte.

| WIDTH | Standard-cell area before / after (µm²) | Area reduction | Worst setup before / after (ns) |
|---|---:|---:|---:|
| 8 | 47,213.082 / 44,696.106 | 5.331% | −3.217651 / −1.853540 |
| 16 | 48,461.994 / 46,074.420 | 4.927% | −3.261416 / −1.861665 |

The mappings contain 69,038 / 71,203 cells, the same 6,254 / 6,574 FFs and 64 fixed SRAM interfaces. Main 640 ps timing closes 0/30 profiles; reference 6.4 ns timing closes 26/30. Worst hold remains −0.008036 ns. The runner exits nonzero because timing remains open, while the independent auditor verifies that the measurement matrix itself is complete. These are prelayout measurements with synthetic SRAM timing, not macro signoff or a completed timing fix.

The new graphs have the same complete state inventory and retain the two binary-to-one-hot cursor transformations. Four independent reset queries and four cursor-domain closure queries pass. Four mapped dormant/capture queries also pass, independently varying each unowned lane's payload while observing all public/macro outputs, nonpayload next state and newly captured payload. Complete encoded output/next-state partitions continue; current complete mapped correspondence and actual mapped fault qualification are not claimed.

## Reproduction

Run from a Git clone containing the reference commit. Use fresh labels; outputs remain under `build/verification/`.

```sh
python3 verification/tl_tx_qualification/run_structure.py --label NEW_STRUCTURE
python3 verification/tl_tx_qualification/run_equivalence.py --label NEW_RTL
python3 verification/tl_tx_prepared/run_unit.py --kd28-root PATH --label NEW_UNIT --widths 8 9 10 11 12 13 14 15 16
python3 verification/tl_control_partition/run_peers.py --kd28-root PATH --integrated --label NEW_PEERS
python3 verification/tl_control_partition/run_peers.py --kd28-root PATH --integrated --label NEW_MINIMUM --header-depth 1 --bank-depth 1
python3 verification/tl_control_partition/check_evidence.py --peers-label NEW_PEERS --minimum-label NEW_MINIMUM --peers-only --output-label NEW_WIRE
python3 verification/tl_tx_prepared/check_capture.py --labels NEW_PEERS NEW_MINIMUM
python3 verification/tl_tx_prepared/run_faults.py --peers-label NEW_PEERS --label NEW_FAULTS
python3 verification/tl_tx_prepared/run_formal.py --kd28-root PATH --label NEW_OWNERSHIP --widths 8 9 10 11 12 13 14 15 16 --depths 1 2 3
python3 verification/tl_tx_prepared/run_physical.py --lib-root LIB_ROOT --kd28-root PATH --sta STA_PATH --label NEW_PHYSICAL --widths 8 16
python3 verification/tl_tx_prepared/check_physical.py --label NEW_PHYSICAL
```

`run_mapped_pair.py --label NEW_PAIR --physical NEW_PHYSICAL` emits the actual complete state graphs; its strict same-encoding check rejects the binary-to-one-hot cursor change. That rejection is not an equivalence result. Use `run_encoding_cec.py --label NEW_ENCODED --pair NEW_PAIR --physical NEW_PHYSICAL --prepare-only` to emit the complete encoded wrappers and pruned graphs, then `run_partitioned_cec.py --label NEW_PARTITIONS --source NEW_ENCODED --group-size 2048 --timeout 120`. Preparation alone reports no equivalence. `run_reset_state.py`, `run_cursor_invariants.py` and `run_dormant_state.py` accept `--pair NEW_PAIR` for the candidate's actual graphs.

Next complete and audit the candidate's mapped correspondence, including reset, cursor closure, dormant capture and actual mapped faults. Continue timing repair at the original 640 ps clock and IO budgets. Synthetic SRAM timing views remain an abstraction; full Endpoint/Switch, protocol/payload, digital PHY, INC, security, manageability and macro signoff obligations remain open.
