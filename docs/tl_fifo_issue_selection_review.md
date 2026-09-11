# FIFO prefetch reservation selection experiment

This is an unadopted timing candidate based on `6f10b33539624664cc4231bbb681e7b1d62dc401`. The last fully qualified physical/mapped baseline remains the [header visibility change](tl_tx_header_visibility_review.md). Final physical measurements, mapped correspondence and adoption are pending; the full dual-IP Goal remains active.

The actual baseline critical path traverses Header qualification and opposite-class FIFO consumption before updating unread count. `upli_receive_fifo` now computes cache space from the current cached count and pending SRAM result before the consume decision arrives. `flag_issue` selects existing space or space released by an actual consume. It no longer feeds consume through the reservation subtract/add/compare cone. Ports, parameters, all state and all other transition equations remain unchanged, including invalid count-3 behavior.

## Completed semantic evidence

- The pre-change fault that ignores a pending SRAM result is detected in six complete-state FIFO comparisons. Independent resets remain healthy. The runner's nonzero exit and `complete=false` correctly report inequivalence, not a tool failure.
- The final expression's missing-pending and missing-consume faults each produce six additional real CEC differences, with unchanged reset behavior.
- FIFO default and raw/remasked behavior passes all 36 configurations: data widths 8/32/512, depths 1/2/3/5/129/257, with 72 independent reset proofs against the frozen `6839cac` reference. The proof observes every actual FF transition and output, without constraining cached count to reachable values.
- Six actual SRAM FIFO depth regressions and 36 production unit configurations pass. All 32 production peer configurations pass independent wire/queue/partition/capture audits. Ordinary and optimized Python wire evidence agrees; all 128 trace files are byte-identical to the adopted header-visibility baseline.
- Strict Verilator lint passes. Independent static RTL lint with the confirmed `i_clk` input reports no errors or advisories.

The additional full buffered composition and 27-configuration production ownership matrices are running. The production-top physical matrix uses the same actual standard-cell libraries, synthetic SRAM views, periods and IO budgets. Partial measurements do not establish adoption or timing closure. A first workspace `make test rtl-smoke prepared-tx-smoke` invocation completed model/tool tests but stopped when `rtl-smoke` refused to overwrite an existing `tl_publish/sim/final` directory. Preserve that log; rerun from a clean clone rather than deleting prior evidence.

## Reproduction and next gate

The exact candidate is `rtl/upli/upli_receive_fifo.v`, SHA-256 `3348d06961770df6da9e10e44077624e6b160312254b72bdc5a9240fe7ff3b06`. Run the commands in the [implementation plan](tl_fifo_issue_selection_plan.md) with fresh labels. Candidate artifacts use `fifo_issue_*` under `build/verification/{tl_tx_qualification,tl_tx_prepared,tl_tx_buffered,tl_control_partition}`. Fault-source folders retain exact before/after expressions and both source hashes; proof runs freeze the actual mutated RTL. No faulty file replaces production RTL.

After the complete physical audit, compare both widths' setup, hold, area and state inventory. If justified, complete actual mapped correspondence and all adoption gates. If rejected, retain its source and measurements and restore the exact adopted FIFO source. This experiment does not establish full protocol, real SRAM timing, layout, power or complete Endpoint/Switch signoff.
