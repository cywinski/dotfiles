"""Interval and frontier helpers for research figures, numpy only.

Vendor this file next to the figure scripts that import it. viz scripts use it
directly; figstyle.py (the matplotlib fallback) re-exports it.

    from figstats import binomial_ci, diff_ci, mean_ci, pareto_front
"""

from __future__ import annotations

import math
import warnings

import numpy as np

# Two-sided 95% t critical values by degrees of freedom. Seed counts are small
# enough that the normal approximation understates the interval.
_T95 = {
    1: 12.706, 2: 4.303, 3: 3.182, 4: 2.776, 5: 2.571, 6: 2.447, 7: 2.365,
    8: 2.306, 9: 2.262, 10: 2.228, 12: 2.179, 15: 2.131, 20: 2.086, 30: 2.042,
    40: 2.021, 60: 2.000, 120: 1.980,
}


def mean_ci(runs, confidence: float = 0.95):
    """Mean and 95% t-interval across seeds. `runs` is (n_seeds, n_points).

    Returns `(mean, lo, hi)`. Report the interval, not the standard deviation:
    a band of +/- 1 SD says how spread the seeds are, not how well the mean is
    resolved.
    """
    if confidence != 0.95:
        raise ValueError("only the 95% interval is tabulated; use scipy for others")
    runs = np.asarray(runs, dtype=float)
    n = runs.shape[0]
    mean = runs.mean(axis=0)
    if n < 2:
        warnings.warn(
            "one seed: the band is a line, not an interval — say 'single seed' in the caption",
            stacklevel=2,
        )
        return mean, mean, mean
    sem = runs.std(axis=0, ddof=1) / math.sqrt(n)
    crit = _t95(n - 1)
    return mean, mean - crit * sem, mean + crit * sem


def binomial_ci(successes, trials):
    """Rate and 95% Wilson interval for `successes` out of `trials`.

    Returns `(rate, lo, hi)`, elementwise. Use it for any rate over binary
    outcomes: accuracy on n items, a monitor's catch rate, a calibration bin.
    The normal-approximation interval collapses to a point at 0% and 100% and
    runs past [0, 1] near them, which is exactly where small-n rates live.
    """
    k = np.asarray(successes, dtype=float)
    n = np.asarray(trials, dtype=float)
    if np.any(n <= 0):
        raise ValueError("every rate needs at least one trial")
    if np.any((k < 0) | (k > n)):
        raise ValueError("successes must lie in [0, trials]")
    z = 1.959964
    rate = k / n
    denom = 1 + z**2 / n
    center = (rate + z**2 / (2 * n)) / denom
    half = z * np.sqrt(rate * (1 - rate) / n + z**2 / (4 * n**2)) / denom
    return rate, center - half, center + half


def pareto_front(x, y, minimize_x: bool = True, maximize_y: bool = True):
    """Indices of the non-dominated points, ordered along the frontier.

    A point is on the frontier when no other point is at least as good on both
    axes and strictly better on one.
    """
    x = np.asarray(x, dtype=float)
    y = np.asarray(y, dtype=float)
    cost_x = x if minimize_x else -x
    cost_y = -y if maximize_y else y
    best = np.inf
    front = []
    for i in np.lexsort((cost_y, cost_x)):
        if cost_y[i] < best:
            front.append(i)
            best = cost_y[i]
    return np.array(front, dtype=int)


def _t95(df: int) -> float:
    # Round the degrees of freedom down, never to the nearest key: a smaller df
    # gives a larger t, so the interval errs wide rather than overstating how
    # well a handful of seeds resolves the mean.
    covered = [k for k in _T95 if k <= df]
    return _T95[max(covered)] if covered else _T95[1]


def diff_ci(treatment, baseline):
    """Mean difference (treatment - baseline) and its 95% Welch interval.

    An ablation claims a difference, so the figure has to show the interval of
    the difference. Two overlapping per-variant intervals do not mean the
    difference is indistinguishable from zero.
    """
    treatment = np.asarray(treatment, dtype=float)
    baseline = np.asarray(baseline, dtype=float)
    delta = treatment.mean() - baseline.mean()
    n_t, n_b = treatment.size, baseline.size
    if n_t < 2 or n_b < 2:
        warnings.warn(
            "one seed per arm: the difference has no interval — say so in the caption",
            stacklevel=2,
        )
        return delta, delta, delta
    var_t = treatment.var(ddof=1) / n_t
    var_b = baseline.var(ddof=1) / n_b
    sem = math.sqrt(var_t + var_b)
    if sem == 0:
        return delta, delta, delta  # every seed identical: the interval is a point
    df = (var_t + var_b) ** 2 / (var_t**2 / (n_t - 1) + var_b**2 / (n_b - 1))
    half = _t95(int(df)) * sem
    return delta, delta - half, delta + half
