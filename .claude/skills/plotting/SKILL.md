---
name: plotting
description: Use this skill every time when plotting data or doing plotting scripts.
---

# Plotting

- Use matplotlib for plotting.
- Make plots elegant and readable.
- Labels on the plot are harder to read than you think. There should never be smaller font on the plot anywhere than 14.
- Accuracy and similar metrics should be plotted in the range 0-100.
- Confidence intervals should be plotted using `fill_between` when possible, otherwise use error bars.
- Add borders/edges around plotted elements (e.g. `edgecolor="black"`, `linewidth=0.8` on bars, markers, patches).
- Show a grid by default: `ax.grid(True, linestyle="--", alpha=0.2)`.
- Save all plots to `output/plots/` (or project-specific equivalent).
