# Figure 1: the teaser

**Answers:** what the paper's one phenomenon is. It shows the idea and the
evidence that it happens, in one view.

Test it with one question: *if a reader looks at nothing but this figure, what
should they come away believing?* Write that answer down as one sentence. It
becomes the caption's bold opening, and every element in the figure has to
serve it.

## Draft it first, and redraw it often

- **Start Figure 1 as soon as there is a claim**, before the experiments are
  finished. Drafting it forces the core mental picture into the open. If you
  cannot sketch the picture, the claim is not settled yet.
- **Find the picture before you draw it.** Explain the idea as a 30-second
  whiteboard sketch to someone in the field, or picture the paper's one view
  with your eyes closed. Whatever you would draw first is the concept panel.
- **Expect to redraw it** as the results come in. The teaser is the figure
  most worth iterating on, because most readers see it and nothing else.

## Structure: the idea on top, the evidence beneath

- **Concept panel first.** It shows a schematic of what changes: the setup,
  the intervention, and the predicted effect. When two conceptual panels share
  one understanding, merge them into one diagram rather than two side by side.
- **Empirical panels underneath**, showing the concept producing a measurable
  effect. Use one or two results in familiar shapes, and only the headline.
  Ablations and robustness checks belong in later figures.
- **Lead with what changed in the model**, not the application or the
  benchmark. Panel order follows the explanation, not the order the
  experiments were run.
- **Introduce the condition colors here.** The intervention's color in the
  concept panel is its color in the results beneath, and in every later
  figure. A reader learns the mapping once.

The concept is a schematic, so it is TikZ ([diagram.md](diagram.md)); the
results are data, so they are viz. They meet in one `figure*`: the diagram at
its natural width, and the results strip built at `size="paper"`. Both use the
viz palette, and with `viz.set_defaults(font="sans")` both are sans, so the
seam does not show.

## Traps

| Trap | Fix |
| --- | --- |
| A teaser that is a results grid with no picture of the idea | Add the concept panel. Results alone say *that*, not *what* |
| A concept panel that needs the method section to parse | Redraw it from the whiteboard version; shorten every label |
| The teaser's colors disagree with later figures | One condition-to-color mapping, imported by every script |
| Four results panels "to be thorough" | One or two headline results; the rest move to Section 4 |
| Decorative icons (robots, brains, magnifying glasses) | Every element should carry information; drop the clip art |
| The schematic scaled down to fit the width | Shorten labels or stack the layout; never `scale=` (see diagram.md) |

## Template

Three pieces: the concept in TikZ, the results in viz, and the
`figure*` that stacks them. The placeholder labels are the parts to rewrite.

`figs/teaser_concept.tex`: the contents of `tikz-preamble.tex`, then:

```latex
\begin{document}
\begin{tikzpicture}[fig, node distance=4mm and 12mm]

  \node[muted] (base) {Base model};
  % The intervention is the one accented element, in the color the results
  % below use for it.
  \node[ours,  above right=1mm and 12mm of base] (treat) {Train with\\intervention};
  \node[muted, below right=1mm and 12mm of base] (ctrl)  {Train without\\(control)};
  \node[block, right=of treat, minimum width=26mm] (up)   {Target behaviour\\appears};
  % Aligned under `up` rather than placed right of `ctrl`: the arms differ in
  % width, and the outcomes should line up as one column.
  \node[block, minimum width=26mm] (flat) at (up |- ctrl) {Target behaviour\\unchanged};

  \draw[flow] (base.east) -- (treat.west);
  \draw[flow] (base.east) -- (ctrl.west);
  \draw[flow, draw=figorange] (treat) -- (up);
  \draw[flow] (ctrl) -- (flat);

  % Literal model output is monospace, so it reads as data, not as a label.
  \node[edgelbl, font=\ttfamily\scriptsize, right=2mm of up]   {"example output"};
  \node[edgelbl, font=\ttfamily\scriptsize, right=2mm of flat] {"example output"};

  \node[font=\sffamily\footnotesize\bfseries, anchor=north west]
    at (current bounding box.north west) {(a)};

\end{tikzpicture}
\end{document}
```

`figs/teaser_results.py`, reading `figs/teaser_curves.csv`
(`condition,seed,step,value`) and `figs/teaser_evals.csv`
(`condition,eval,seed,value`):

```python
"""Figure 1 results strip: the effect over training, and where it lands.

Regenerate: uv run --with-editable "$(viz path)" --with numpy python figs/teaser_results.py
"""

import csv
from collections import defaultdict

import numpy as np
import viz
from figstats import mean_ci

CURVES = "figs/teaser_curves.csv"  # condition,seed,step,value
EVALS = "figs/teaser_evals.csv"  # condition,eval,seed,value
CONDITIONS = ["Control", "Intervention"]
EVAL_ORDER = ["Held-out tasks", "New domain"]
# The same condition colors as the concept panel and every later figure.
ROLES = {"baseline": "Control", "intervention": "Intervention"}  # or viz-roles.json


def main():
    viz.set_defaults(size="paper")
    viz.set_roles(**ROLES)  # before the panels are built: each chart takes its colors when it is made
    runs = defaultdict(lambda: defaultdict(list))
    with open(CURVES) as handle:
        for row in csv.DictReader(handle):
            runs[row["condition"]][row["seed"]].append((float(row["step"]), float(row["value"])))
    lines, bands = {}, {}
    for c in CONDITIONS:
        curves = [sorted(points) for points in runs[c].values()]
        steps = [s for s, _ in curves[0]]
        mean, lo, hi = mean_ci(np.array([[v for _, v in curve] for curve in curves]))
        lines[c] = list(zip(steps, mean.tolist()))
        bands[c] = (lo.tolist(), hi.tolist())

    scores = defaultdict(lambda: defaultdict(list))
    with open(EVALS) as handle:
        for row in csv.DictReader(handle):
            scores[row["eval"]][row["condition"]].append(float(row["value"]))
    bars = {e: [float(np.mean(scores[e][c])) for c in CONDITIONS] for e in EVAL_ORDER}
    seeds = {e: [scores[e][c] for c in CONDITIONS] for e in EVAL_ORDER}  # every seed as a dot over its bar

    fig = viz.panels([
        # viz labels every x value when there are few; thin the ticks so they don't collide.
        viz.line(lines, bands=bands, markers=False, end_values=False, xticks=steps[::max(1, len(steps) // 4)],
                 xlabel="Training step",
                 ylabel="Behavior rate", title="(b) Over training"),
        viz.bars(bars, series=CONDITIONS, runs=seeds, sort=False, decimals=1, ylabel="Behavior rate",
                 title="(c) After training"),
    ], cols=2)
    fig.save("figs/teaser_results.pdf")
    fig.save("figs/teaser_results.png")


if __name__ == "__main__":
    main()
```

The paper stacks them. The diagram goes in at its natural width, never
rescaled, and the results strip at `\linewidth`, which is the `paper` width it
was built at:

```latex
\begin{figure*}[t]
  \centering
  \includegraphics{figs/teaser_concept.pdf}\\[2mm]
  \includegraphics[width=\linewidth]{figs/teaser_results.pdf}
  \caption{\textbf{Training with the intervention produces the target behaviour,
  and it transfers to held-out evaluations.} (a) Setup: the same base model
  trained with and without the intervention. (b) Target behaviour rate over
  training. (c) Final rate on three held-out evaluations. Mean of 5 seeds;
  bands and bars are 95\% intervals across seeds.}
  \label{fig:teaser}
\end{figure*}
```

## Checklist

- [ ] One sentence says what a reader who sees only this figure should believe, and it opens the caption.
- [ ] A concept panel on top shows the idea; the results beneath show it happening.
- [ ] One or two headline results, in shapes the reader already knows.
- [ ] The accented condition has the same color in the diagram, the results, and every later figure.
- [ ] The diagram is included at natural width and the results strip was built at `size="paper"`, with neither rescaled.
- [ ] Literal model text is monospace.
