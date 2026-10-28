---
name: plotting
description: "Use this skill every time when plotting data or writing plotting scripts, for any chart, plot, graph or figure: results, reports, chat answers, papers, slides, blog drafts, artifacts. Figures are made with the viz library in the house style (white background, Newsreader serif, gray = control, orange/blue/sage/purple/ochre = interventions, direct value labels) and saved as PNG, PDF, SVG or HTML. Covers choosing the claim and the plot shape that says it, titles vs. captions, colors that keep their meaning, uncertainty, sizing for papers, and templates for learning curves, scaling laws, benchmark and ablation comparisons, Pareto trade-offs, heatmaps and confusion matrices, calibration diagrams, Figure-1 teasers, and TikZ method diagrams. Prefer it over other figure skills and plain matplotlib; then read one reference."
---

A figure is an argument, not a screenshot of an array. It makes one claim, and
a reader who skips the prose should still get that claim right. A reader skims
the title, the abstract, and then the figures, so for most readers the figures
*are* the result.

Every chart is made with **viz**, the house figure library: one call per chart,
the house style built in, and checks that flag a figure breaking the rules
below. matplotlib (`assets/figstyle.py`) is the fallback only for the few
shapes viz cannot draw, and TikZ is for diagrams.

## Run viz

`viz path` prints where the viz clone is. Every chart has a template there: a
short script in `examples/NN_name.py` with its figure in
`docs/gallery/NN_name.png`. `docs/guide.md` has viz's style rules and
`docs/reference.md` every chart and option.

```bash
uv run --with-editable "$(viz path)" python figs/make_figs.py
```

If `viz` is not found, the dotfiles `setup.sh` installs it (it clones
safety-research/viz beside the dotfiles and runs its `install.sh`). To render
a JSON spec instead of Python: `viz render spec.json -o fig.png`.

```python
import viz
fig = viz.hbar({"Closed book": 59, "With search": 12},
               roles={"baseline": "Closed book", "intervention": "With search"},
               title="With search, wrong answers fell from 59% to 12%")
fig.save("fig.png")   # 2x PNG for chat, web and slides; .pdf for papers; .svg portable; .html for pages
```

To use a figure in an artifact, call `fig.html(standalone=False)`: it returns
inline SVG and the Google Fonts link.

For the stats viz does not compute (an interval of a difference, a Wilson
interval, a Pareto front), vendor `assets/figstats.py` next to the figure
scripts. It needs only numpy:

```sh
mkdir -p figs && cp ~/.claude/skills/plotting/assets/figstats.py figs/
```

Record the viz commit with the figure (`git -C "$(viz path)" rev-parse HEAD`
in the run's metadata) so it can be regenerated exactly.

## Decide the claim before you plot

Most unreadable figures are decided before the first line of plotting code:
the figure tries to say two things, or says its one thing in a shape the reader
has to decode.

- **Sketch the figure before the experiment runs.** Say, in a sentence, what
  the figure should show if the hypothesis holds: which axis, which conditions,
  where each line or bar should land. That sketch is the prediction. It also
  tells you which runs the figure needs and which it does not. When the real
  figure disagrees with it, that is a finding about the hypothesis, not a
  plotting problem: say so, and revise the hypothesis before the figure.
- **Use a shape the reader already knows.** "Simple" means simple relative
  to what the field already recognizes. To an ML reader a reliability diagram
  is simple, and a novel glyph is not. Each familiar shape carries a sentence
  the reader decodes before reading the caption: bars say "A is higher than
  B", diverging lines say "this one goes up, that one doesn't", a log-log line
  says "the trend is linear in log space", a frontier says "we push the
  trade-off". Pick the shape whose sentence *is* your claim (the table in
  *Read exactly one reference* pairs each with its reference). If no shape's
  sentence fits, the claim is usually not sharp yet. Fix the claim before you
  invent a new kind of chart.
- **One idea per plot.** Every mark answers the figure's one question. An
  element that answers a different question (a pass@k series on a
  single-attempt figure, a baseline the text never discusses) belongs in
  another figure or the appendix.
- **The axis of variation is the comparison.** Put the things the claim
  compares next to each other: adjacent bars, a shared x-axis, the same row of
  panels. If the claim is about where conditions end up, a grouped bar of
  final values beats ten overlapping training curves.
- **Rank what the eye sees first.** The condition the claim is about takes the
  accent color; supporting context (baselines, other runs) stays gray. viz does
  this through roles (see *Colors*); with no roles, `highlight=` accents one bar.
- **Draw a diagram when a chart is the wrong tool.** A branching process, a
  pipeline, or a mechanism is clearer drawn than plotted
  ([references/diagram.md](references/diagram.md)).

### Pick the chart

The viz templates in `examples/` are grouped by the research question a figure
answers; copy the closest one.

- **Comparisons.** Rates by condition: `hbar`, with `notes=` for "352 of 400"
  and `ci=` for intervals. Each model without and with the intervention:
  `bars`. Several runs or seeds: never show one run when there are more; show
  the mean with every run as a dot, `bars(..., runs=...)`. Each model's effect
  with its interval, against zero: `dotplot`. Where the outcomes went: `stacked`.
- **Training dynamics.** `line` with `runs=` for every seed faint behind the
  mean, or `bands=` for an interval; `smooth=0.9` for a noisy reward;
  `marks={step: "RL starts"}` for events; shares over training with
  `area(..., normalize=True)`.
- **Evaluations.** Several models on a few benchmarks:
  `bars(scores, series=[models])`. A results table with the best per column
  bold: `table`. Models against evals or attacks: `heatmap`. Two measures per
  model: `scatter`, with `frontier="upper-left"` for a trade-off frontier.
  Scaling: `line(..., xscale="log", yscale="log")`.
- **Monitors and probes.** ROC curves: `line(..., diagonal="Chance")`. Scores
  on two classes: `histogram`. A 2×2 confusion matrix: `tiles`. Probe accuracy
  by layer: `line` with a `ref=` line at chance.
- **Interpretability.** Activations in 2D: `scatter` with groups. A score on
  every token: `tokens`. Steering strength: `line(..., xscale="category")`.
- **Self-reports and ratings.** A −3..+3 scale: `likert`. Before and after:
  `dumbbell`.
- **Distributions.** `histogram`; `box` for many items per group; `strip` for
  a few, one dot each.
- **Transcripts.** `quotes` for contrasting replies, `episodes` for transcripts
  side by side, `chat` for an agent's turns and tool calls. Literal model text
  is set in monospace there, so it reads as data rather than as labels.
- **Multi-panel figures.** `panels([...], cols=2)` with one shared legend.

## Non-negotiables

1. **Every number comes from a run.** Read metrics from the run's own output
   under `output/`. Never plot a remembered, rounded, or plausible number, and
   never leave synthetic demo data in a script that ships. Made-up data for a
   "dream figure" says so in the subtitle: "Example data".
2. **Show the uncertainty, or say there is none.** One seed is an anecdote.
   Show the interval across seeds (`ci=`, `bands=`, or every run with `runs=`)
   and state the seed count in the text; if you only have one run, say
   "single seed" rather than implying more. **Say what the interval is
   over.** An interval across 100 samples of one task measures sampling noise
   on that task. It says nothing about whether the number holds on the next
   task. Resample over the unit the claim generalizes over (seeds, tasks,
   prompts, environments), name that unit, and name the uncertainty the bars
   cannot cover, such as a single environment or a single model family. A
   rate over n binary outcomes gets a `binomial_ci()` (Wilson) interval, not a
   mean interval over 0/1 values, which collapses to a point at 0% or 100%.
3. **Label the axes with units.** "Loss" is a label; "step" without knowing
   whether it counts optimizer steps or tokens is not. Rescale large units in
   the label ("Tokens seen (billions)") rather than printing 400,000,000.
4. **Build at the final size.** Pick the size for where the figure goes
   (*Size*) and never shrink a figure afterwards: rescaling a figure rescales
   its text with it.
5. **Vector for papers.** `.pdf` for `\includegraphics`, `.svg` for a portable
   copy. A rasterized plot blurs under the zoom every reviewer uses. PNG is
   right for chat, web pages and slides.
6. **Colors keep their meaning.** One color per condition across every figure
   of a write-up, set once with roles (*Colors*). Never `jet`, `rainbow` or
   `hsv` in a fallback figure: they invent structure that is not in the data.

## Titles and captions: decided by where the figure goes

| The figure goes to | Title | Caption |
| --- | --- | --- |
| A report, chat answer, slide, post or artifact | **The finding**, as one plain sentence (*Write the title*) | None in or under the figure; context goes in the surrounding text |
| A paper (`.tex`) | **None** (`title=None`); viz then warns "No title", which is expected here and the only warning to leave | The LaTeX caption carries the claim (*Write the caption*) |

Panel titles inside `panels` are still used in a paper: `(a) Over training`,
`(b) After training`. Prose refers to "Fig. 2b".

### Write the title

Readers look at the title first and remember it better than the chart, so the
title carries the finding and nothing else on the figure competes with it.

- One finding, stated literally: what was compared and what happened, in about
  10 plain words. If it needs a semicolon, make two figures.
- Name what the eye sees first, the highlighted bar or the biggest gap. If the
  point is a small difference, change the chart (highlight it, drop other
  bars), not the words.
- Say what was measured, not what it means: "rated the episode higher", not
  "felt better"; "chose to stop", not "wanted to stop".
- Numbers, not adjectives: "fell from 41% to 28%", not "dropped sharply".
- No colon setups ("The fix: search"), mirrored phrasing, metaphors, wordplay
  or questions. No names coined inside the project. Field terms the readers use
  daily are fine.

Subtitle: none by default. Add one only to say "Example data" when the numbers
are made up, or what the error bars are ("Error bars are 95% intervals"), or
both. Sample sizes, methods, training details and model names go in the text.
If the measure needs a sentence to explain, show a simpler measure.

Numbers as measured: viz prints each value with the digits it has and never
rounds it. A computed value such as a mean over seeds can have more digits
than it deserves (18.475%): choose its precision with `decimals=` and quote the
printed number in the title. One name per condition, the same in every figure
and in the text.

Check: read the title alone. Someone outside the project should be able to
repeat the finding without asking what a word means.

### Write the caption

For a paper, the caption is written *with* the figure, not after the draft.
Captions in current papers run a median of about 28 words, and half are three
sentences or more. The dominant shape is a **short bold phrase naming the
claim, then the detail a reader needs to trust it**:

```latex
\caption{\textbf{LPO reaches the reward plateau in a third of the compute.}
Held-out reward against training compute for LPO and two baselines; mean of 5
seeds, bands are 95\% intervals. The dotted line is the pretrained model.}
```

- **Lead with the finding, not the setup.** "Training curves for LPO and
  baselines" names the axes, which the axes already do.
- **The figure must stand alone.** A reader who skips your Section 4 should
  still get the claim right.
- **Put the method facts here**: seed count, what the band or bar means, any
  smoothing, any normalization, which points were fitted and which excluded,
  and whether a frontier line is measured or a guide.
- **Say what is not shown** when it matters: a single seed, a truncated axis,
  a run cut short.
- **Do not restate the axis labels** in prose.

A one-panel figure earns roughly 25-40 words; a multi-panel figure earns more,
and each panel needs its own clause.

**A figure in a research update carries more around it.** In an experiment
report, a chat answer, or a Slack thread, the reader knows the project but not
this run. Their job is to catch a mistake before it compounds. The title states
the finding; the paragraph next to the figure gives everything they need to
check it: the data and the split, n and the unit of n, how the interval was
computed, the key hyperparameters, and every non-obvious choice (a filter, an
excluded run, a changed prompt).

## Colors

Name the conditions once and let viz color them: gray for the control, then
orange, blue, sage, purple and ochre for the interventions in that order, a
light-to-dark blue ramp for ordered conditions (doses, sizes, steps), and light
gray for everything else. A reference (chance, the base model) is a dashed
`ref=` line, not a color.

```python
viz.set_roles(control="Closed book", intervention="With search", second="Rerank", ordered=["1M", "3M", "10M"])
```

- **One file per write-up.** A `viz-roles.json` in the working folder or above
  (`{"baseline": "Closed book", "intervention": ["With search"]}`) sets the
  roles for every script there; `viz roles` shows them. If one exists, use its
  label names exactly.
- **Set roles before building panels.** A chart takes its colors when it is
  made, so call `viz.set_roles` (or pass `roles=` to each chart) before the
  charts that go into `panels`.
- Don't hand-pick `colors=`; role names work as colors
  (`legend={"Search": "intervention"}`). The one exception: outcomes rather
  than conditions (right, unsure, wrong) are blue, beige and orange,
  `colors=["blue", "beige", "coral"]`.
- Without roles, several series take orange, blue, sage, purple and ochre in
  that order. Purple and blue look alike to some color-blind readers, so with
  four or more, name lines at their ends (`line` does by default).
- In a fallback matplotlib or TikZ figure, take the hex values from
  `viz.PALETTE` so a condition keeps its color across both.

## Order

Put categories in order of their values (`sort=True`, largest first;
`sort="asc"` when smaller is better) unless the order means something, such as
model release, size, training step, or the column order of a results table.
`sort=False` keeps a chosen order without the warning. In grouped bars, keep
the method order identical in every group and in the legend.

## Size

| Size | Width | For |
| --- | --- | --- |
| `screen` (default) | 1008 px | reports, chat, web pages, artifacts |
| `slide` | 16:9 | a full slide |
| `paper` | 6.75 in | full text width of a two-column paper (`figure*`) |
| `column` | 3.25 in | one column of a two-column paper |

One size per write-up: `viz.set_defaults(size="paper")`. A one-column NeurIPS
page (5.5 in) is `viz.Size(width=610, plot=260, title=16, inches=5.5)`. PDFs
come out at the printed width, so they need no scaling. Titles must fit on one
line at the chosen size.

**Paper fonts.** viz sets labels in Newsreader, a serif. For a paper whose
diagrams are sans (the TikZ preamble uses Helvetica), pass
`viz.set_defaults(font="sans")` so labels, ticks and legends switch to DM Sans
and the figures read as one family. Figure text must match across a paper's
figures, not the body font.

## Where the figure goes

| The figure is for | Write it to |
| --- | --- |
| A paper (`.tex`) | `figs/` beside the `.tex` in the working tree — `\includegraphics` resolves paths relative to the source |
| An experiment, report, or answer in chat | `output/<experiment>/<timestamp>/plots/`, per the repo's output convention |

Timestamp the *run directory*; the figure stem inside it stays greppable and
stable (`loss_curve.pdf`, not `loss_curve_20260831.pdf`) so a rerun overwrites
rather than accumulates. A flat `output/plots/` is acceptable only in a repo
that already uses it — then timestamp the filename instead.

Keep the generating script beside its output (`figs/loss_curve.py` →
`figs/loss_curve.pdf`). A figure whose script is gone cannot be corrected when
a reviewer asks for one more seed. Never write a figure you intend to hand over
into `/tmp` or a scratch directory; pulling logs or intermediate data there is
fine — the figure, and the script that made it, are not intermediate.

Build the figure at its printed size, **and** still write `width=\linewidth`:

```latex
\begin{figure}[t]          % figure* for a `paper`-size figure in a two-column paper
  \centering
  \includegraphics[width=\linewidth]{figs/loss_curve.pdf}
  \caption{\textbf{...}}
  \label{fig:loss}
\end{figure}
```

Sized correctly, `width=\linewidth` scales by 1.0 and changes nothing, but it
still fits if the venue's column turns out narrower than you assumed. What it
cannot do is rescue a figure built at the wrong size. A `paper`-size figure
only gets a 6.75-inch `\linewidth` inside a `figure*`; in a plain `figure` in
a two-column paper it silently scales to about a half.

## Multi-panel figures

Roughly a quarter of figures in current ML papers are multi-panel. Build them
with `viz.panels([...], cols=2)`; each chart's title becomes its panel title.

- **Letter every panel** in its title, `(a) ...`, `(b) ...`, and read them in
  argument order: left to right, top to bottom.
- **Share the axis when panels share a quantity**: pass the same `ticks=` and
  `domain=` to each chart. Two panels of the same metric on silently different
  ranges is the multi-panel version of a truncated bar axis.
- **One legend for the figure**: `panels` merges them.
- **If the panels do not support one claim, they are separate figures.** A
  2×3 grid of unrelated plots is a contact sheet.

## When viz cannot draw it

viz has no dashed series, no hollow markers, no free text inside a line or bar
plot (only `scatter` takes `annotations=`), and no frontier per group. For a figure whose claim needs one of those (an
extrapolated fit, several methods' frontiers over every run), use the
matplotlib fallback: vendor `assets/figstyle.py` *and* `assets/figstats.py`
next to the script, color conditions with `viz.PALETTE` hex values, and say in
the hand-over that the figure is a fallback. The references show which
figures need it. Run it with
`uv run --with matplotlib --with numpy python figs/<name>.py` and read the
audit line its `save()` prints (`clean` is the bar).

## Read exactly one reference

Pick by the question the figure answers, not by the shape you have in mind.
The middle column is the sentence the shape says before anyone reads the
caption. If it is not your claim, you have the wrong row.

| The figure answers | The shape says | Read |
| --- | --- | --- |
| How does a metric move over training, and is the gap bigger than seed noise? | "this goes up" / "this one goes up, that one doesn't" | [references/curves.md](references/curves.md) |
| How does performance change with scale, and what does the trend predict? | "the trend is linear in log space" | [references/scaling.md](references/scaling.md) |
| Which method wins across benchmarks, or which ablated component mattered? | "A is higher than B" / "removing X costs this much" | [references/comparison.md](references/comparison.md) |
| What is traded off against what — reward vs KL, quality vs cost or latency? | "we push the frontier" | [references/pareto.md](references/pareto.md) |
| What does this 2D grid, confusion matrix, or sweep look like? | "the effect lives in this region" | [references/matrix.md](references/matrix.md) |
| Can a model's stated probabilities be taken at face value? | "A is better calibrated than B" | [references/calibration.md](references/calibration.md) |
| What is the paper's one phenomenon (Figure 1, the teaser)? | "here is the idea, and here it is happening" | [references/teaser.md](references/teaser.md) |
| What is the method, architecture, or pipeline? | (a diagram, not a chart) | [references/diagram.md](references/diagram.md) |

Every reference's template writes to `figs/`, the paper destination, with
`TITLE = None`. For an experiment or a chat answer, put the script and its
output under the run's `plots/` directory instead, set `TITLE` to the finding,
and use the default `screen` size.

Do not read references for figures you are not making. For anything outside
those eight, copy the closest template in `$(viz path)/examples/`.

## Before you hand it over

- **Fix every viz check warning** that saving prints. The one exception is
  "No title" on a paper figure. `viz check spec.json` checks specs without
  rendering.
- **Look at every PNG before you send it.** The checks cover titles, colors and
  order, not layout: tick labels that run into each other (thin them with
  `xticks=`), end labels that collide with a reference line, values with more
  digits than they deserve (`decimals=`).
- Every axis labelled, with units.
- The claim in the title (or the caption) is visible in the figure without the
  prose, and it is the sentence the figure's shape says.
- If you sketched a prediction, compare the result with it, and report a
  mismatch as a result rather than smoothing it over.
- Uncertainty shown, with n and the unit of n stated.
- Each condition has the color it has in the project's other figures.
- No unexplained series, no legend entry for something that was cut.
- The script reruns from scratch and reproduces the same file.
- In a write-up, use `fig.alt_text()` as the image's alt text.
- **Deliver the file**: send it to the user (`SendUserFile` or a clickable
  link), not just its path.
