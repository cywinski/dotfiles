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

## The color bar is an axis

Label it with the quantity and its units (`label=`), exactly as you would
label an x-axis; viz writes each cell's value on it too. Its range is a
decision: by default it runs from 0 (0-100 for percents), which washes out a
grid whose values all sit far from zero, such as a loss between 2.0 and 2.9.
Pass `domain=(lo, hi)` for the measured range, and say so. Several heatmaps on
one scale share the same `domain=`, or a reader compares colors that are not
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
- **Keep classes in one order on both axes**, so the diagonal is the correct
  predictions.

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
    # The color bar starts at 0 unless told otherwise; span the measured range so the pattern shows.
    measured = [v for v in loss.values() if v is not None]
    fig = viz.heatmap(data, cols=cols, col_groups=[("Batch size", cols)], unit="", decimals=2,
                      domain=(min(measured), max(measured)), label="Validation loss", title=TITLE)
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
    fig = viz.heatmap(data, cols=CLASSES, col_groups=[("Predicted", CLASSES)], decimals=0,
                      label="Share of the true class", title=TITLE)
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
- [ ] Color bar labelled with quantity and units; its `domain=` chosen, and shared across heatmaps on one scale.
- [ ] Axis ticks show real values, not indices.
- [ ] Confusion matrix: normalization named in the caption, support reported.
- [ ] Failed or missing runs are visually distinct from bad-but-real values.
