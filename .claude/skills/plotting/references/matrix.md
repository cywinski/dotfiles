# Heatmaps, sweeps, and confusion matrices

**Answers:** what a 2D grid of measurements looks like — a hyperparameter
sweep, a confusion matrix, a correlation structure, a layerwise diagnostic.

A heatmap encodes value as color, and color is the least precise channel a
reader has. That buys you pattern recognition across a whole grid at once, and
it costs you the ability to compare two nearby cells accurately. Use it when
the *shape* of the grid is the finding.

## First, check a heatmap is the right figure

A 3×4 grid is not a heatmap; it is four lines with three points each, and a
line plot lets the reader read values off an axis instead of a color ramp.
Reach for a heatmap at roughly 5×5 and up, or when the two axes are genuinely
symmetric (a confusion or correlation matrix at any size).

## Color scale is a decision, not a default

| The data is | Use | Because |
| --- | --- | --- |
| A magnitude with a natural low end (loss, accuracy, count) | One hue: `scale="coral"` (default), `"blue"` or `"sage"` | Light to dark reads as low to high, and survives greyscale |
| A signed difference, correlation, or delta to a baseline | `scale="diverging", center=0` with a symmetric `domain=` | The midpoint color must land on zero, or the sign is unreadable. Pass `low="blue", high="coral"` when higher is worse |
| Anything at all | Never `jet`, `rainbow`, `hsv` (in a fallback figure) | They have bright bands at arbitrary values, inventing edges the data does not have |

## Every cell carries its value

viz writes each cell's value on it, in white or ink by contrast, so the color
shows the pattern and the number gives the reading. Name the quantity and unit
in the title or caption, as you would an axis. Several heatmaps on one scale
share the same `domain=`, or a reader compares colors that are not
comparable.

## Confusion matrices

- **Normalize, and say how.** Raw counts under class imbalance make the largest
  class look like the model's whole behavior. Row-normalized gives recall per
  true class; column-normalized gives precision. Name which one in the caption.
- **Cell values are on.** Up to about 12×12 the numbers fit; past that,
  `values=False` and let the pattern carry it.
- **Order the classes meaningfully** — by frequency, by semantic grouping, or
  identically to a matrix you are comparing against. Alphabetical order
  scatters the block structure that is often the finding.
- **A 2×2 matrix is four numbers**, such as a monitor's catches and misses:
  `viz.tiles` with big numbers reads better than a heatmap.

## Traps

| Trap | Fix |
| --- | --- |
| Sweep axes labelled `0,1,2` | Label with the actual values; mark log-spaced axes as log |
| Best cell left for the reader to find | Name it in the title or caption |
| NaNs rendered as the lowest color | Pass `None` for a failed run (viz leaves it blank) and say what blank means |
| Two heatmaps, two autoscaled ranges | One shared `domain=` |

## Template — hyperparameter sweep

`figs/sweep.py`, reading `figs/sweep.csv` (`lr,batch_size,loss`):

```python
"""Validation loss over a learning-rate x batch-size sweep.

Regenerate: uv run --with-editable "$(viz path)" python figs/sweep.py
"""

import csv

import viz

DATA = "figs/sweep.csv"
TITLE = None  # paper: the caption carries the claim. Report or chat: the finding, as a sentence.


def main():
    viz.set_defaults(size="column")
    loss = {}
    with open(DATA) as handle:
        for row in csv.DictReader(handle):
            loss[(float(row["lr"]), int(row["batch_size"]))] = float(row["loss"])

    lrs = sorted({lr for lr, _ in loss})
    sizes = sorted({bs for _, bs in loss})
    # Label rows and columns with the swept values, never indices. A missing run stays None,
    # which viz leaves blank instead of shading it as the lowest value.
    data = {f"lr {lr:.0e}": [loss.get((lr, bs)) for bs in sizes] for lr in lrs}
    cols = [str(bs) for bs in sizes]
    fig = viz.heatmap(data, cols=cols, col_groups=[("Batch size", cols)], unit="", decimals=2, title=TITLE)
    fig.save("figs/sweep.pdf")
    fig.save("figs/sweep.png")


if __name__ == "__main__":
    main()
```

## Template — confusion matrix

`figs/confusion.py`, reading `figs/confusion.csv` (`true,pred`), one row per
example, row-normalized:

```python
"""Row-normalized confusion matrix.

Regenerate: uv run --with-editable "$(viz path)" python figs/confusion.py
"""

import csv
from collections import Counter

import viz

DATA = "figs/confusion.csv"
CLASSES = ["refuse", "partial", "deflect", "comply"]  # a meaningful order, the same as any matrix it is compared with
TITLE = None  # paper: the caption carries the claim. Report or chat: the finding, as a sentence.


def main():
    viz.set_defaults(size="column")
    counts = Counter()
    with open(DATA) as handle:
        for row in csv.DictReader(handle):
            counts[(row["true"], row["pred"])] += 1

    support = {t: sum(counts[(t, p)] for p in CLASSES) for t in CLASSES}
    # Row-normalized: each cell is the % of that true class, so the diagonal is per-class recall.
    data = {f"True {t} (n={support[t]})": [100 * counts[(t, p)] / support[t] for p in CLASSES] for t in CLASSES}
    fig = viz.heatmap(data, cols=CLASSES, col_groups=[("Predicted", CLASSES)], decimals=0, title=TITLE)
    fig.save("figs/confusion.pdf")
    fig.save("figs/confusion.png")


if __name__ == "__main__":
    main()
```

The row labels carry the support per class, and the caption says
row-normalized — 100% over three examples is not the same result as 100% over
three thousand.

## Checklist

- [ ] The grid is big enough that a heatmap beats a line plot.
- [ ] One-hue scale for magnitudes, diverging *centered on zero* for signed data.
- [ ] Quantity and unit named; heatmaps on one scale share `domain=`.
- [ ] Axis ticks show real values, not indices.
- [ ] Confusion matrix: normalization named in the caption, support reported.
- [ ] Failed or missing runs are visually distinct from bad-but-real values.
