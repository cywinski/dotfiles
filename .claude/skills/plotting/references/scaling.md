# Scaling laws

**Answers:** how a metric changes with model size, data, or compute — and what
the trend predicts at a scale you did not run.

The figure is a log-log scatter of measured runs with a fitted power law
through them. Its whole value is the fit, so the fit has to be defensible: a
straight line drawn through four points on log axes will look convincing
whether or not it means anything.

## Fit the form the field uses

For a metric with a floor — loss, error — the two-parameter power law
`L = A·N^(-α)` is wrong at large N, because it goes to zero and real loss does
not. Fit the three-parameter form:

```
L(N) = E + A · N^(-α)
```

`E` is the irreducible loss (entropy of the data, Bayes error). Forcing `E = 0`
bends the fit and flattens `α`, which is exactly the parameter you are
reporting. Fit `E` too — and fit the error on `L`, not on `log(L - E)`, which
is dominated by whichever runs sit closest to the floor. If the fitted `E`
comes out at zero or at `min(L)`, the runs do not constrain the floor: say so
rather than reporting the boundary as a measurement.

Report `α` with an interval — a bootstrap over the runs is enough — and put it
in the figure, not only the prose. A scaling exponent with no uncertainty
invites a reviewer to ask how many points it came from.

## What belongs in the fit

- **One regime only.** Runs that are under-trained, warmup-limited, or hitting
  a different bottleneck are a different law. Plot them if they are
  interesting, but exclude them from the fit and say which points were fit.
- **At least 4 points, ideally spanning a decade or more.** Fewer than 4, or
  all within a factor of 3, is a trend line, not a scaling law — label it that
  way.
- **Comparable runs.** Same data, same tokenizer, same evaluation. A scaling
  plot silently comparing two eval sets is a broken figure that looks fine.

## Extrapolation must look like extrapolation

If the point of the figure is a prediction at a scale you did not run, draw the
fit solid over the fitted range and dashed beyond it, and shade the
extrapolated region. A solid line running off the right of the plot claims
measurement where there is none. viz has no dashed series, so a figure that
extrapolates uses the matplotlib fallback below.

## Traps

| Trap | Fix |
| --- | --- |
| Linear ticks reading 400,000,000 | Log axes print powers of ten; on a linear axis, rescale the unit in the label ("Parameters (billions)") |
| Fit line drawn but residuals hidden | Add a residual strip under the main panel — curvature there means the form is wrong |
| Points shown without which were fit | Say which were fit in the caption; to mark excluded points in the figure (hollow), use the fallback |
| Both axes log but only one labelled as such | Log axes are conventional here; still name the units |
| `α` in the prose only | Put the fitted law with its interval in the title (report) or the caption's first sentence (paper) — it is the result |
| Different model families in one color | One series (and color) per family; the law may differ between them |

## Template

`figs/scaling.py`, reading `figs/scaling.csv` (`family,n_params,loss,fit`)
where `fit` is `1` for points included in the fit. It draws the measured runs
per family on log-log axes, the fitted law over the fitted range, and a
residual panel beneath. Run it with `uv run --with-editable "$(viz path)" --with numpy python figs/scaling.py`, with `figstats.py` vendored in `figs/`.

```python
"""Loss vs. parameters with a fitted power law.

Regenerate: uv run --with-editable "$(viz path)" --with numpy python figs/scaling.py
"""

import csv

import numpy as np
import viz

DATA = "figs/scaling.csv"
FIT_FAMILY = "Dense"  # the family whose law the figure reports
TITLE = None  # paper: the caption carries the claim and the fitted law. Report or chat: the finding, with alpha.


def load(path):
    n, loss, fitted, family = [], [], [], []
    with open(path) as handle:
        for row in csv.DictReader(handle):
            n.append(float(row["n_params"]))
            loss.append(float(row["loss"]))
            fitted.append(row["fit"] == "1")
            family.append(row["family"])
    return np.array(n), np.array(loss), np.array(fitted), np.array(family)


def fit_power_law(n, loss, alphas=np.linspace(0.02, 1.5, 800)):
    """Least squares for L = E + A*N^-alpha.

    For a fixed alpha the model is linear in (E, A), so scanning alpha and
    solving each slice exactly needs no nonlinear optimizer. It also fits the
    error on L rather than on log(L - E), which is dominated by whichever runs
    sit closest to the floor and collapses the fit to E = 0.
    """
    best = None
    for alpha in alphas:
        design = np.stack([np.ones_like(n), n**-alpha], axis=1)
        coef, *_ = np.linalg.lstsq(design, loss, rcond=None)
        if coef[0] < 0 or coef[1] <= 0:
            continue  # a negative floor or amplitude is not a scaling law
        sse = float(((design @ coef - loss) ** 2).sum())
        if best is None or sse < best[0]:
            best = (sse, float(coef[0]), float(coef[1]), float(alpha))
    if best is None:
        raise ValueError("no fit with a non-negative irreducible term")
    _, e, a, alpha = best
    return e, a, alpha


def bootstrap_alpha(n, loss, draws=200, seed=0):
    """95% percentile interval of alpha over resampled runs."""
    rng = np.random.default_rng(seed)
    alphas = []
    for _ in range(draws):
        idx = rng.integers(0, len(n), len(n))
        if len(set(idx.tolist())) < 3:
            continue
        try:
            alphas.append(fit_power_law(n[idx], loss[idx])[2])
        except ValueError:
            continue  # a degenerate resample is not a reason to lose the figure
    if len(alphas) < draws // 4:
        raise ValueError(f"only {len(alphas)}/{draws} resamples fit; too few runs for an interval")
    return np.percentile(alphas, [2.5, 97.5])


def main():
    viz.set_defaults(size="column")
    n, loss, fitted, family = load(DATA)
    pick = fitted & (family == FIT_FAMILY)
    e, a, alpha = fit_power_law(n[pick], loss[pick])
    lo, hi = bootstrap_alpha(n[pick], loss[pick])
    print(f"{FIT_FAMILY}: L = {e:.2f} + {a:.1f} N^-{alpha:.3f}, alpha in [{lo:.3f}, {hi:.3f}], "
          f"{int(pick.sum())} runs fit, {int((~fitted).sum())} excluded")

    def law(x):
        return e + a * x**-alpha

    # The fit is drawn over the fitted range only: viz has no dashed series, so an
    # extrapolation figure needs the figstyle fallback in references/scaling.md.
    # Markers are on for every series, so evaluate the fit at the fitted runs' sizes, not a dense grid.
    grid = np.sort(n[pick])
    # The fit goes first so the measured runs draw over it.
    series = {f"{FIT_FAMILY} fit": list(zip(grid.tolist(), law(grid).tolist()))}
    series |= {f: list(zip(n[family == f].tolist(), loss[family == f].tolist())) for f in sorted(set(family))}
    # No end labels: the legend names the series, and both panels then share the same plot width.
    main_panel = viz.line(series, xscale="log", yscale="log", unit="", markers=True, end_labels=False, legend=True,
                          roles={"intervention": FIT_FAMILY, "second": [f for f in set(family) if f != FIT_FAMILY][0]},
                          xlabel="Non-embedding parameters", ylabel="Validation loss", title=TITLE)
    resid = {FIT_FAMILY: list(zip(n[pick].tolist(), (100 * (loss[pick] - law(n[pick])) / loss[pick]).tolist()))}
    span = float(np.ceil(max(abs(y) for _, y in resid[FIT_FAMILY]) * 10) / 10)
    resid_panel = viz.line(resid, xscale="log", ref=0, unit="", markers=True, end_labels=False, height=90,
                           ticks=[-span, 0, span], domain=(-span, span),
                           xlabel="Non-embedding parameters", ylabel="Residual (%)")
    fig = viz.panels([main_panel, resid_panel], cols=1)
    fig.save("figs/scaling.pdf")
    fig.save("figs/scaling.png")


if __name__ == "__main__":
    main()
```

## Fallback — extrapolated fit (matplotlib)

When the figure's point is a prediction beyond the runs, the fit has to go
dashed past the data and the extrapolated region shaded, and excluded runs
should be hollow; viz draws none of those. Vendor `figstyle.py` and
`figstats.py` into `figs/`, run it with
`uv run --with matplotlib --with numpy python figs/scaling.py`, and take the
colors from `viz.PALETTE` hex values so the families keep their house colors:

```python
"""Loss vs. parameters with a fitted power law. Regenerate: python figs/scaling.py"""

import csv

import numpy as np
from figstyle import BASELINE, PALETTE, TEXT, figure_grid, save, si_ticks, use_style

DATA = "figs/scaling.csv"
PREDICT_TO = 1e11  # extrapolate the fit out to this many parameters


def load(path):
    n, loss, fitted, family = [], [], [], []
    with open(path) as handle:
        for row in csv.DictReader(handle):
            n.append(float(row["n_params"]))
            loss.append(float(row["loss"]))
            fitted.append(row["fit"] == "1")
            family.append(row["family"])
    return np.array(n), np.array(loss), np.array(fitted), np.array(family)


def fit_power_law(n, loss, alphas=np.linspace(0.02, 1.5, 800)):
    """Least squares for L = E + A*N^-alpha.

    For a fixed alpha the model is linear in (E, A), so scanning alpha and
    solving each slice exactly needs no nonlinear optimizer. It also fits the
    error on L rather than on log(L - E), which is dominated by whichever runs
    sit closest to the floor and collapses the fit to E = 0.
    """
    best = None
    for alpha in alphas:
        design = np.stack([np.ones_like(n), n**-alpha], axis=1)
        coef, *_ = np.linalg.lstsq(design, loss, rcond=None)
        if coef[0] < 0 or coef[1] <= 0:
            continue  # a negative floor or amplitude is not a scaling law
        sse = float(((design @ coef - loss) ** 2).sum())
        if best is None or sse < best[0]:
            best = (sse, float(coef[0]), float(coef[1]), float(alpha))
    if best is None:
        raise ValueError("no fit with a non-negative irreducible term")
    _, e, a, alpha = best
    return e, a, alpha


def bootstrap_alpha(n, loss, draws=200, seed=0):
    rng = np.random.default_rng(seed)
    alphas = []
    for _ in range(draws):
        idx = rng.integers(0, len(n), len(n))
        if len(set(idx.tolist())) < 3:
            continue
        try:
            alphas.append(fit_power_law(n[idx], loss[idx])[2])
        except ValueError:
            continue  # a degenerate resample is not a reason to lose the figure
    if len(alphas) < draws // 4:
        raise ValueError(f"only {len(alphas)}/{draws} resamples fit; too few runs for an interval")
    return np.percentile(alphas, [2.5, 97.5])


def main():
    use_style()
    n, loss, fitted, family = load(DATA)
    e, a, alpha = fit_power_law(n[fitted], loss[fitted])
    lo, hi = bootstrap_alpha(n[fitted], loss[fitted])

    fig, (ax, res) = figure_grid(
        nrows=2, ncols=1, width=TEXT, ratio=0.62,
        sharex=True, gridspec_kw={"height_ratios": [3, 1]},
    )

    def curve(x):
        return e + a * x**-alpha

    measured = np.geomspace(n[fitted].min(), n[fitted].max(), 100)
    beyond = np.geomspace(n[fitted].max(), PREDICT_TO, 100)

    ax.plot(measured, curve(measured), color=BASELINE, zorder=1)
    ax.plot(beyond, curve(beyond), color=BASELINE, linestyle="--", zorder=1)
    ax.axvspan(n[fitted].max(), PREDICT_TO, color=BASELINE, alpha=0.08, linewidth=0)

    markers = ("o", "s", "^", "v", "P", "X")
    families = sorted(set(family))
    if len(families) > len(markers):
        raise ValueError(f"{len(families)} families, {len(markers)} markers: add more")
    for marker, name in zip(markers, families):
        pick = family == name
        ax.scatter(n[pick & fitted], loss[pick & fitted], marker=marker,
                   color=PALETTE["blue"], label=name, zorder=2)
        ax.scatter(n[pick & ~fitted], loss[pick & ~fitted], marker=marker,
                   facecolor="none", edgecolor=PALETTE["blue"], linewidth=0.7, zorder=2)

    ax.set_xscale("log")
    ax.set_yscale("log")
    ax.set_ylabel("Validation loss")
    ax.set_xlim(right=PREDICT_TO)
    ax.text(
        0.03, 0.06,
        rf"$L = {e:.2f} + {a:.1f}\,N^{{-{alpha:.3f}}}$" "\n"
        rf"$\alpha \in [{lo:.3f},\ {hi:.3f}]$, {int(fitted.sum())} runs",
        transform=ax.transAxes, va="bottom", fontsize=7,
    )
    if len(set(family)) > 1:
        ax.legend(loc="upper right")

    res.axhline(0, color=BASELINE, linewidth=0.6)
    res.scatter(n[fitted], 100 * (loss[fitted] - curve(n[fitted])) / loss[fitted],
                color=PALETTE["blue"], s=8)
    res.set_ylabel("Resid. (%)")
    res.set_xlabel("Non-embedding parameters")
    si_ticks(ax, "y")
    si_ticks(res, "x")

    save(fig, "figs/scaling")


if __name__ == "__main__":
    main()
```

## Checklist

- [ ] The fitted form has an irreducible term, and `E` is reported.
- [ ] `α` carries an interval, and the number of fitted runs is stated.
- [ ] Excluded points are visually distinct and the exclusion is justified.
- [ ] Extrapolation is dashed and shaded (fallback); nothing solid leaves the data range.
- [ ] A residual panel shows the fit is not systematically curved.
