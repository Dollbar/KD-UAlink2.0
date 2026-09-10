# Production transmit physical baseline checkpoint

The actual `tl_tx_prepared` hierarchy has been mapped at WIDTH 8 and 16 using the confirmed TSMC28 HPC+ SSG 0.81 V/125 C standard-cell library, HEADER_DEPTH=2 and BANK_DEPTH=3. The RTL is unchanged from `eb1d3004f9cdc18e63c3f2f290e230ac7683215c`.

| WIDTH | Cells including SRAM instances | Positive-edge FF | SRAM macros | Standard-cell area, µm² |
|---|---:|---:|---:|---:|
| 8 | 73,677 | 6,254 | 64 | 47,213.082 |
| 16 | 75,364 | 6,574 | 64 | 48,461.994 |

Area excludes SRAM: no characterized macro area or total silicon area is claimed. Each macro is the actual fixed `KD28_SRAM_SDP_256X32` interface; clocks remain directly connected to the original `i_clk`. The flow maps standard cells around the macro instances and never synthesizes behavioral memory arrays.

## Completed measurements and live work

WIDTH 8 has completed all 30 measurements: five confirmed standard-cell corners × three synthetic SRAM views × 0.640/6.400 ns periods. All actual path families and the complete 64-macro clock/data/address inventory are present. The independent partial audit re-read all 30 logs and verified the 5.760 ns setup shift and unchanged hold slack between the two clock periods for all 15 corner/view pairs.

None of its 15 main-frequency cases closes timing. Thirteen of the 15 reference-period cases pass; two fail hold. Worst setup is −3.217651 ns (SSG cold), and worst hold is −0.008036 ns. A reported setup-critical path starts at Response Header FIFO `cnt_cached[0]` and ends at `cnt_unread[1]`. Inspection of the actual RTL identifies the long dependency through wire consumption and prefetch scheduling. This is the next architectural timing concern; the old standalone prepared-partition timing does not predict it. The minimum path includes a Data input feeding a macro input under the slow synthetic hold requirement.

WIDTH 16 STA remains running in the existing unified-exec session **4476**. `build/verification/tl_tx_prepared/physical_baseline/live_job.json` and `docs/goal_checkpoint.json` record the handoff. Poll the original handle before doing anything that could restart or overwrite work. The live file `results.json` continues changing; `checkpoint_results.json` is the immutable snapshot for this checkpoint. Full 60-case evidence audit is not yet complete.

## Timing assumptions and qualification

The three SRAM Liberty views are explicitly synthetic repository assumptions. The external `profiles.yaml` specifies setup/hold/clock-to-Q in ns as fast 0.060/0.020/0.120, typical 0.100/0.030/0.200 and slow 0.160/0.050/0.320. They are not foundry PVT corners. The Cartesian matrix tests the actual standard-cell corners against each assumption; it does not equate their process labels.

All runs use an ideal common clock, setup/hold uncertainty 0.032/0.010 ns, clock/input transition 0.050 ns, input max/min delays 0.128/0.020 ns, output max/min delays 0.128/−0.020 ns, and 0.005 pF output load. No false paths, multicycle exceptions or parasitics are introduced. Six actual path families are required: input-to-register, register-to-register, register-to-output, register-to-macro, input-to-macro and macro-to-register. Successful measurement is distinct from setup/hold/limit closure.

Twelve report-parser tests and six tests that mutate actual mapped inventories pass under ordinary and optimized Python. They reject missing/wrong macro or pin counts, omitted path families, wrong clock mode/view, nonfinite results, tool failures, unconstrained endpoints, missing completion, misclassified negative timing, changed clocks and unknown cells. Original missing-checker test failures remain preserved. The completed WIDTH 8 area was independently recalculated from actual standard-cell Liberty areas and mapped instance counts.

## Commands and remaining gates

```sh
python3 verification/tl_tx_prepared/run_physical.py --lib-root /authorized/NLDM --kd28-root /authorized/repository --sta /configured/sta --label physical_baseline
python3 verification/tl_tx_prepared/test_timing_report.py
python3 verification/tl_tx_prepared/test_physical_audit.py --graph build/verification/tl_tx_prepared/physical_baseline/w8/mapped.json
python3 verification/tl_tx_prepared/check_physical.py --label physical_baseline
python3 -O verification/tl_tx_prepared/check_physical.py --label physical_baseline --output build/verification/tl_tx_prepared/physical_baseline/evidence_optimized.json
```

The first command is already running: do not invoke it again for this checkpoint. For later fresh runs, supply a new label. Outputs include RTL/script snapshots, exact tool commands, mapped Verilog/JSON, area, raw STA logs and result summaries. Exit 1 is expected when timing violations remain; it does not by itself establish that all measurements completed. The full auditor deliberately refuses an incomplete matrix.

After the live job terminates, audit the full matrix, bind final evidence and clear the live-job checkpoint. Then prove actual mapped-state/output correspondence and repair setup/hold with preserved source-capture, partition-queue, wire-consumption and throughput contracts. Full payload/Data-bank formal checks, final UPLI/Endpoint/Switch integration, remaining protocol items, digital PHY, INC, security and manageability remain open. Neither current timing measurements nor prior ownership proofs finish the full Goal. No external publication is part of this local checkpoint.
