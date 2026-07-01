# Figure notes: robustness coefplots (2026-07-01)

LaTeX for the two robustness coefplots.
Notation matches the GRC table notes in `preamble.tex` ($\phi$, $\Delta_{\text{never}}$, $\bar{\Delta}$) and the caption style follows `fig:hetplotDelta` (`\caption` + `\floatfoot{\small ...}`).
Captions are Title Case to match the paper's existing figure captions.
Copy `robustness_coefplot_{IDN,TZA}.pdf` from `RP7/output/figures/` into the Overleaf `figures/` folder first.

## Indonesia

```latex
\begin{figure}[htbp]
    \centering
    \caption{Robustness of Restricted GRC Estimates to Additional Controls, Indonesia}
    \label{fig:robustness_coefplot_IDN}
    \includegraphics[width=\linewidth]{figures/robustness_coefplot_IDN.pdf}
    \floatfoot{\small Each panel plots the point estimate and $95\%$ confidence interval of one parameter of the restricted GRC model, estimated on the Indonesian consumption sample (urban location, unbalanced panel).
    From left to right, the parameters are the comparative-advantage slope $\phi$, the extrapolated never-migrant return $\Delta_{\text{never}}$, and the sample-weighted average switcher return $\bar{\Delta} = \sum_{\underline{d}} \pi_{\underline{d}} \Delta_{\underline{d}}$, defined as in the notes to Table \ref{tab:GRC_IDN_consumption_urban_unb}.
    The ``Main'' row reproduces our preferred specification (the final column of Table \ref{tab:GRC_IDN_consumption_urban_unb}), which includes time fixed effects, a female indicator, age squared, and years of education and its square.
    Each subsequent row re-estimates the Main specification with exactly one additional covariate added to that set; the rows are not cumulative and differ only in which covariate is added: years of working experience (``$+$ Experience''); the running maximum of experience over the panel (``$+$ Max experience''); experience as a share of potential working years (``$+$ Experience share''); the running maximum of that share (``$+$ Max exp.\ share''); and an indicator for urban birthplace (``$+$ Urban birth'').
    Confidence intervals use GMM standard errors.
    The point estimates are stable across specifications and preserve their signs ($\phi < 0$, $\Delta_{\text{never}} > 0$, and $\bar{\Delta} > 0$).}
\end{figure}
```

## Tanzania

```latex
\begin{figure}[htbp]
    \centering
    \caption{Robustness of Restricted GRC Estimates to Additional Controls, Tanzania}
    \label{fig:robustness_coefplot_TZA}
    \includegraphics[width=\linewidth]{figures/robustness_coefplot_TZA.pdf}
    \floatfoot{\small Each panel plots the point estimate and $95\%$ confidence interval of one parameter of the restricted GRC model, estimated on the Tanzanian consumption sample (urban location, unbalanced panel).
    From left to right, the parameters are the comparative-advantage slope $\phi$, the extrapolated never-migrant return $\Delta_{\text{never}}$, and the sample-weighted average switcher return $\bar{\Delta} = \sum_{\underline{d}} \pi_{\underline{d}} \Delta_{\underline{d}}$, defined as in the notes to Table \ref{tab:GRC_TZA_consumption_urban_unb}.
    The ``Main'' row reproduces our preferred specification (the final column of Table \ref{tab:GRC_TZA_consumption_urban_unb}), which includes time fixed effects, a female indicator, age squared, and years of education and its square.
    Each subsequent row re-estimates the Main specification with exactly one additional covariate added to that set; the rows are not cumulative and differ only in which covariate is added: years of working experience (``$+$ Experience''); the running maximum of experience over the panel (``$+$ Max experience''); experience as a share of potential working years (``$+$ Experience share''); and the running maximum of that share (``$+$ Max exp.\ share'').
    Confidence intervals use GMM standard errors.
    The point estimates are stable across specifications and preserve their signs ($\phi < 0$, $\Delta_{\text{never}} > 0$, and $\bar{\Delta} > 0$).}
\end{figure}
```

## Notes on choices

- The urban-birth row (``$+$ Urban birth'') appears only in the Indonesia figure; the cell is not estimated for Tanzania, so the Tanzania note omits it.
- The three panel labels ($\phi$, $\Delta_{\text{never}}$, Average $\Delta$) are embedded in the figure. If they later move to LaTeX subcaptions (per the usual subfig/subcaption workflow), the ``From left to right'' clause can be dropped.
- Caption is Title Case to match the existing figure captions (e.g. `fig:heterogeneity`); switch to sentence case if the paper migrates to that convention.
