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
  count. A bin of 6 examples should look as uncertain as it is. Error bars
  are right here, because the bins are discrete.
- **ECE depends on the binning.** Report it with the bin count and scheme
  ("ECE, 10 equal-width bins"), never as a bare number.

## Encoding

- Both axes run 0-100 with the same ticks, and the panel is close to square,
  so the diagonal sits at 45°.
- The diagonal is a grey dashed reference (`BASELINE`). It is not a series and
  gets no legend entry. The caption names it.
- Hue *and* marker shape carry the model, so the comparison survives
  greyscale. Use the project's condition colors.
- The confidence histogram goes underneath on a shared x-axis, at about a
  third of the height. It answers "where is the mass?", which decides how
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
correct:

```python
"""Reliability diagram: does stated confidence match accuracy? Regenerate: python figs/calibration.py"""

import csv
from collections import defaultdict

import numpy as np
from figstyle import BASELINE, COLUMN, PALETTE, binomial_ci, figure_grid, save, use_style

DATA = "figs/calibration.csv"
N_BINS = 10
BINNING = "width"  # "mass" when confidences pile up at one end

# One color and one marker per condition, identical in every figure of the
# project. In a project this mapping lives in figs/colors.py.
COLORS = {"Model A": PALETTE["blue"], "Model B": PALETTE["orange"]}
MARKERS = {"Model A": "o", "Model B": "s"}


def load(path):
    """-> {model: (probs, labels)} as float arrays."""
    rows = defaultdict(lambda: ([], []))
    with open(path) as handle:
        for row in csv.DictReader(handle):
            probs, labels = rows[row["model"]]
            probs.append(float(row["prob"]))
            labels.append(float(row["label"]))
    return {model: (np.array(p), np.array(y)) for model, (p, y) in rows.items()}


def reliability(probs, labels):
    """Per non-empty bin: mean confidence, accuracy with its Wilson interval, count; and ECE."""
    if BINNING == "mass":
        edges = np.quantile(probs, np.linspace(0, 1, N_BINS + 1))
    else:
        edges = np.linspace(0, 1, N_BINS + 1)
    # Interior edges only, so a prediction of exactly 1.0 lands in the top bin.
    index = np.digitize(probs, edges[1:-1])
    bins = [b for b in range(N_BINS) if np.any(index == b)]
    conf = np.array([probs[index == b].mean() for b in bins])
    hits = np.array([labels[index == b].sum() for b in bins])
    count = np.array([np.sum(index == b) for b in bins])
    acc, lo, hi = binomial_ci(hits, count)
    ece = np.sum(count * np.abs(acc - conf)) / count.sum()
    return conf, acc, lo, hi, count, ece


def main():
    use_style()
    data = load(DATA)

    fig, (ax, hist) = figure_grid(
        2, 1, width=COLUMN, ratio=1.25, sharex=True, gridspec_kw={"height_ratios": [3, 1]}
    )
    ax.plot([0, 100], [0, 100], linestyle="--", color=BASELINE, linewidth=0.8)

    for model, (probs, labels) in data.items():
        conf, acc, lo, hi, count, ece = reliability(probs, labels)
        print(f"{model}: n={len(probs)}, bins={len(count)}, min bin n={count.min()}, ECE={ece:.4f}")
        ax.errorbar(
            100 * conf, 100 * acc, yerr=100 * np.stack([acc - lo, hi - acc]),
            fmt=f"{MARKERS[model]}-", color=COLORS[model], linewidth=0.9,
            markeredgecolor="black", markeredgewidth=0.4,
            elinewidth=0.6, capsize=1.5, label=f"{model} (ECE {100 * ece:.1f})",
        )
        hist.hist(100 * probs, bins=np.linspace(0, 100, 21), histtype="step",
                  color=COLORS[model], linewidth=0.9)

    ax.set_xlim(0, 100)
    ax.set_ylim(0, 100)
    ax.set_xticks(range(0, 101, 20))
    ax.set_yticks(range(0, 101, 20))
    ax.set_ylabel("Observed accuracy (%)")
    hist.set_xlabel("Stated confidence (%)")
    hist.set_ylabel("Examples")
    fig.legend(loc="outside upper center", ncol=len(data))

    save(fig, "figs/calibration")


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
- [ ] Points at mean bin confidence, each with a Wilson interval.
- [ ] Confidence histogram beneath on a shared x-axis.
- [ ] ECE reported with its bin count and scheme, and n stated in the caption.
- [ ] Hue and marker both encode the model, in the project's condition colors.
