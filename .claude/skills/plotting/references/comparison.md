# Benchmark comparisons and ablations

**Answers:** which method wins — across a suite of benchmarks, or across the
components you ablated.

Two questions that look alike and want different figures:

| The comparison is | Use | Because |
| --- | --- | --- |
| Several methods across several benchmarks, scores measured from zero | **Grouped bars** — the headline figure of an evaluation paper | Length is an honest encoding when the axis starts at zero, and the grouping lets a reader scan one method across every benchmark |
| One metric, differences small relative to seed noise | **Dot-and-whisker on the difference** | Position encodes value, so the axis can span only the interesting range without lying |

The rule underneath both: **a bar's length is a promise that the axis starts at
zero.** Truncating a bar axis to make a 0.4-point gap look decisive is the most
common dishonest figure in ML. That is an argument against truncation, not
against bars — accuracy, pass@k, win rate, and counts all start at zero
legitimately, and a bar is the right mark for them.

## Grouped bars across benchmarks

**Roles carry the method family.** The untuned base model is the control
(gray), prior work is `second` (blue), yours is `intervention` (orange), and
variants of one method are an `ordered` light-to-dark ramp. A reader separates
"theirs" from "ours" before reading a single legend entry. Seven arbitrary
colors communicate nothing.

**Keep the method order identical in every group,** and keep it in the legend
order. The figure is read by scanning one method's bar position across groups;
re-sorting per group destroys that.

**Label every bar with its value** (viz does by default). It makes the figure
do the results table's job as well, and a reader quoting your numbers does not
have to squint at the axis. If bars get so dense the labels collide, that is
the signal to drop a method or split the figure, not to shrink the text.

**Order the benchmark groups deliberately** — by difficulty, by size, or to
match the results table. Alphabetical is a missed opportunity.

**The legend sits above the plot**, off the bars; viz places it there.

A grouped chart tops out around 6 methods × 6 groups. Past that, no amount of
styling saves it — use a table.

## Ablations: plot the difference

When the claim is "this component matters", plot `variant − baseline` with a
line at zero, sorted by effect. The reader sees sign, size, and whether the
interval crosses zero, which is the entire question.

Show the interval **of the difference** (`diff_ci` in `figstats.py`). Two overlapping
per-variant intervals do **not** mean the difference is indistinguishable from
zero — a widely repeated error. If a variant's interval crosses zero, the
honest reading is "no detectable effect at this seed count".

With one seed per variant there is no interval. Say "single seed" in the
caption and do not draw whiskers that imply otherwise.

## When the figure should be a table

If the reader needs exact numbers, or there are more than ~8 variants, or the
differences are within noise, a table communicates better than any chart:
`viz.table` for a report, `booktabs` for a paper.

## Traps

| Trap | Fix |
| --- | --- |
| Bar chart with a truncated y-axis | Start at zero, or switch to a delta dot plot |
| Every method a different hue | Gray base, one role per family, an `ordered` ramp within |
| Method order varies per group | Fix the order; match the legend |
| Error bars of unstated meaning | State it: "95% CI over 5 seeds". SD, SEM, and CI differ by large factors |
| Rotated 45° tick labels | Horizontal dots with left-aligned names, or a wider figure |
| "Ours" first regardless of score | Sort honestly; losing on a subset is a result |
| Bar labels colliding | Fewer methods or a split figure — not smaller type |

## Template — grouped benchmark bars

`figs/benchmarks.py`, reading `figs/benchmarks.csv` (`benchmark,method,score`):

```python
"""Benchmark accuracy per method.

Regenerate: uv run --with-editable "$(viz path)" python figs/benchmarks.py
"""

import csv
from collections import defaultdict

import viz

DATA = "figs/benchmarks.csv"
# Method order is fixed in every group and in the legend; benchmarks in the order of the results table.
METHODS = ["Base model", "Prior work", "Ours"]
BENCHMARKS = ["MMLU", "GPQA", "MATH"]
ROLES = {"baseline": "Base model", "second": "Prior work", "intervention": "Ours"}  # or viz-roles.json
TITLE = None  # paper: the caption carries the claim. Report or chat: the finding, as a sentence.


def main():
    viz.set_defaults(size="paper")
    score = defaultdict(dict)
    with open(DATA) as handle:
        for row in csv.DictReader(handle):
            score[row["benchmark"]][row["method"]] = float(row["score"])

    data = {bench: [score[bench][m] for m in METHODS] for bench in BENCHMARKS}
    fig = viz.bars(data, series=METHODS, roles=ROLES, sort=False, ylabel="Accuracy", title=TITLE)
    fig.save("figs/benchmarks.pdf")
    fig.save("figs/benchmarks.png")


if __name__ == "__main__":
    main()
```

## Template — ablation deltas

`figs/ablation.py`, reading `figs/ablation.csv` (`variant,seed,value`).
Run it with `uv run --with-editable "$(viz path)" --with numpy python figs/ablation.py`, with `figstats.py` vendored in `figs/`.

```python
"""Ablation deltas against the full method.

Regenerate: uv run --with-editable "$(viz path)" --with numpy python figs/ablation.py
"""

import csv
from collections import defaultdict

import viz
from figstats import diff_ci

DATA = "figs/ablation.csv"
FULL = "Full method"
TITLE = None  # paper: the caption carries the claim. Report or chat: the finding, as a sentence.


def main():
    viz.set_defaults(size="column")
    runs = defaultdict(list)
    with open(DATA) as handle:
        for row in csv.DictReader(handle):
            runs[row["variant"]].append(float(row["value"]))

    delta, ci = {}, {}
    for variant, values in runs.items():
        if variant == FULL:
            continue
        # The interval of the difference, not two per-variant intervals.
        d, lo, hi = diff_ci(values, runs[FULL])
        delta[variant], ci[variant] = d, (lo, hi)
        print(f"{variant}: {d:+.2f} [{lo:+.2f}, {hi:+.2f}], n={len(values)} vs {len(runs[FULL])}")

    fig = viz.dotplot(delta, ci=ci, ref=0, sort=True, unit="", decimals=1, signed=True,
                      xlabel="Accuracy change vs. full method (points)", title=TITLE)
    fig.save("figs/ablation.pdf")
    fig.save("figs/ablation.png")


if __name__ == "__main__":
    main()
```

## Checklist

- [ ] Bars start at zero; nothing is truncated.
- [ ] Roles carry the method family; gray for the base model.
- [ ] Method order identical across groups and matching the legend.
- [ ] Every bar labelled, and no labels collide.
- [ ] Deltas: intervals are *of the difference*, with n and their meaning in the caption.
- [ ] More than ~8 variants, or numbers needed exactly? Table instead.
