# Calibration (reliability diagrams)

**Answers:** whether a model's stated probability can be taken at face value,
that is, whether the answers it gives with 80% confidence are right 80% of the
time.

The shape is familiar enough that a reader decodes it in a glance: the
diagonal is perfect calibration, points below it are overconfident, and points
above it are underconfident. That only works if the figure keeps the
conventions. If the axes are not square, or one runs 0-1 and the other 0-100,
the reader has to read it the slow way.

## First, check calibration is the question

- **It needs probabilities.** Stated confidences, verbalized probabilities,
  and P(yes) read from logprobs all qualify. A suspicion score or reward on an
  arbitrary scale has no diagonal to compare against. If the question is
  whether the score separates the classes, plot an ROC curve or a catch rate
  at a fixed audit budget instead.
- **Calibration is not accuracy.** A model that always predicts the base rate
  is perfectly calibrated and useless. Pair the diagram with accuracy, or with
  the confidence histogram underneath, which shows *sharpness*: whether the
  model ever commits.

## Binning is a choice the caption names

- **Equal-width bins** (10 by default) read most naturally. When confidences
  pile up at one end, which is common for instruction-tuned models above 90%,
  most bins hold a handful of examples. In that case use **equal-mass**
  (quantile) bins, so every point carries the same n.
- **Plot each bin at its mean predicted probability**, not at the bin center.
  A bin spanning 90-100% whose predictions average 97% belongs at 97.
- **Each point gets a binomial interval** (`binomial_ci()`, Wilson) on its own
  count. A bin of 6 examples should look as uncertain as it is. viz draws the
  intervals as a band along the line (`bands=`).
- **ECE depends on the binning.** Report it with the bin count and scheme
  ("ECE, 10 equal-width bins"), never as a bare number.

## Encoding

- Both axes run 0-100 with the same ticks, and the panel is close to square,
  so the diagonal sits at 45°.
- The diagonal is a gray dashed reference (`diagonal=True`). It is not a
  series and gets no legend entry. The caption names it.
- Each model takes its role color and a legend entry. End labels are off:
  at 100% they collide with the diagonal.
- The confidence histogram goes underneath on a shared x-axis, at about a
  third of the height (`height=` on the histogram). It answers "where is the mass?", which decides how
  much the sparse bins matter.

## Traps

| Trap | Fix |
| --- | --- |
| Bins with 3 examples drawn as confidently as bins with 3,000 | Wilson interval per bin, and the histogram beneath |
| ECE quoted without its binning | Name the bin count and scheme in the legend or caption |
| A non-probability score forced onto [0, 1] and called calibrated | Calibration needs probabilities. Use ROC or catch rate for scores |
| Min-max normalizing confidences before binning | This changes what the diagonal means. Bin the raw probabilities |
| Bar-style reliability diagram (bar height = accuracy per bin) | Points at mean confidence are honest about where the bin sits. Bars imply the bin center |
| Pooling tasks with different base rates into one diagram | Pooled calibration can hide per-task miscalibration that cancels. Split by task if the claim is per task |

## Template

`figs/calibration.py`, reading `figs/calibration.csv` (`model,prob,label`)
with one row per example, `prob` in [0, 1], and `label` 1 if the answer was
correct. Run it with `uv run --with-editable "$(viz path)" --with numpy python figs/calibration.py`, with `figstats.py` vendored in `figs/`.

```python
"""Reliability diagram with the confidence histogram beneath.

Regenerate: uv run --with-editable "$(viz path)" --with numpy python figs/calibration.py
"""

import csv
from collections import defaultdict

import numpy as np
import viz
from figstats import binomial_ci

DATA = "figs/calibration.csv"
BINS = 10  # equal-width; switch to equal-mass (quantile) edges when confidences pile up at one end
ROLES = {"intervention": "Model A", "second": "Model B"}  # or viz-roles.json
TITLE = None  # paper: the caption carries the claim. Report or chat: the finding, as a sentence.


def reliability(prob, label, bins=BINS):
    """-> points at each bin's mean confidence, Wilson intervals, and ECE (all in %)."""
    edges = np.linspace(0, 1, bins + 1)
    which = np.clip(np.digitize(prob, edges[1:-1]), 0, bins - 1)
    points, lo, hi, ece = [], [], [], 0.0
    for b in range(bins):
        pick = which == b
        if not pick.any():
            continue
        conf = prob[pick].mean()  # plot at the mean confidence, not the bin center
        acc, a_lo, a_hi = binomial_ci(label[pick].sum(), pick.sum())
        points.append((100 * conf, 100 * acc))
        lo.append(100 * a_lo)
        hi.append(100 * a_hi)
        ece += pick.mean() * abs(acc - conf)
    return points, (lo, hi), 100 * ece


def main():
    viz.set_defaults(size="column")
    prob, label = defaultdict(list), defaultdict(list)
    with open(DATA) as handle:
        for row in csv.DictReader(handle):
            prob[row["model"]].append(float(row["prob"]))
            label[row["model"]].append(int(row["label"]))

    curves, bands = {}, {}
    for model in prob:
        p, y = np.array(prob[model]), np.array(label[model])
        curves[model], bands[model], ece = reliability(p, y)
        print(f"{model}: n={len(p)}, ECE ({BINS} equal-width bins) = {ece:.1f}%")

    # The diagonal is the reference, unlabeled (the caption names it); end labels would collide with it at 100%.
    ticks = [0, 25, 50, 75, 100]
    diagram = viz.line(curves, bands=bands, roles=ROLES, diagonal=True, domain=(0, 100), ticks=ticks,
                       xticks=ticks, end_labels=False, legend=True, xlabel="Stated confidence (%)",
                       ylabel="Accuracy", title=TITLE)
    spread = viz.histogram({m: [100 * v for v in prob[m]] for m in prob}, roles=ROLES, bins=BINS,
                           stat="percent", domain=(0, 100), ticks=ticks, height=110,
                           xlabel="Stated confidence (%)", ylabel="Answers")
    fig = viz.panels([diagram, spread], cols=1)
    fig.save("figs/calibration.pdf")
    fig.save("figs/calibration.png")


if __name__ == "__main__":
    main()
```

Caption shape: **Model A's confidence tracks its accuracy, and Model B is
overconfident above 60%.** Accuracy per confidence bin (10 equal-width bins,
plotted at each bin's mean confidence) with 95% Wilson intervals. The dashed
line is perfect calibration, and the bottom panel shows where each model's
predictions fall. n = 2,000 questions per model from one held-out split.

## Checklist

- [ ] The quantity is a probability, not an arbitrary score.
- [ ] Both axes 0-100 with matching ticks, panel near-square, diagonal in grey.
- [ ] Points at mean bin confidence, with Wilson intervals as a band.
- [ ] Confidence histogram beneath on a shared x-axis.
- [ ] ECE reported with its bin count and scheme, and n stated in the caption.
- [ ] Each model in its role color, the same as in the project's other figures.
