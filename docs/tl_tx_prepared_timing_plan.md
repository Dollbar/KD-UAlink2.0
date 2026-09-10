# Production transmit physical baseline plan

Execute alone using writing-plans/executing-plans and the established RTL review workflow. Starting source commit: `eb1d3004f9cdc18e63c3f2f290e230ac7683215c`. The production interface, epoch configuration, single clock and synchronous reset contract are unchanged.

Goal: map the actual `tl_tx_prepared` hierarchy to the confirmed TSMC28 standard-cell library and measure complete top-level timing, including actual SRAM transaction ports. Preserve the 64 fixed SRAM instances. Their fast/typical/slow Liberty views are synthetic assumptions, never characterized macro signoff.

- [x] Add source-bound mapping and STA runners under `verification/tl_tx_prepared` and reusable Tcl under `scripts`. Map WIDTH 8/16 with HEADER_DEPTH=2 and BANK_DEPTH=3 at SSG 0.81 V/125 C; save actual netlists, cell inventory and standard-cell-only area.
- [x] Before adopting a report checker, qualify it with missing/wrong macro inventory, incomplete path families, inconsistent clock mode/view, nonfinite values and negative timing. Successful measurement must remain distinct from timing closure.
- [ ] Measure all five confirmed standard-cell corners, three synthetic SRAM views and both 0.640/6.400 ns periods on each mapped netlist. Keep the established IO budgets, clock uncertainty/transition and output loads; no false paths or multicycle exceptions.
- [ ] Require actual input/register/output and register/SRAM path families, full macro pin inventory and actual original clock connections. Preserve negative results and identify the worst setup/hold paths.
- [ ] Independently audit sources, libraries, mapped inventory and all raw reports, record remaining mapped equivalence/physical closure obligations, and commit locally without push.

Commands and output locations are included in each generated script. Full protocol/payload correspondence, final Endpoint/Switch composition, digital PHY, INC, security and manageability remain part of the original Goal.

Live checkpoint: both mappings are complete; WIDTH 8 has 30 measured profiles. WIDTH 16 STA continues in unified-exec session 4476. Full measurement and final evidence audit boxes remain open.
