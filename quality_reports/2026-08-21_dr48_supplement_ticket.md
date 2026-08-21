Title: Supplementary compute request for NCI project dr48

I'd like to request a supplementary allocation for NCI project dr48, ideally in the current quarter.

The project runs the simulation evidence for an econometrics paper on the returns to rural-urban migration that I am preparing for journal submission. The study evaluates bootstrap-based confidence sets, which makes it compute-intensive by construction: each replication re-estimates the model at every point of a test grid, with 999 bootstrap draws per point.

Most of my Q3 grant of 10 KSU went to the study's main production batch. I had priced the batch from a pilot, but the per-replication cost at the production configuration came in well above the pilot-scaled estimate (the production runs concentrate on the most expensive test dimensions), and the jobs hit their walltime limit before completing. I have since reworked the pipeline so that jobs checkpoint incrementally and partial progress persists, and I have now measured per-replication cost directly at the production configuration with a small timing run instead of extrapolating from the pilot.

The measured cost is just over 4 SU per replication, which prices the main evaluation arm at about 9 KSU and the full remaining design at roughly 20 KSU. I have about 600 SU left in Q3, so the study is stalled until the Q4 grant opens on 1 October. I am therefore requesting 20 KSU across two quarters: 10 KSU now would let me restart this quarter, and the remaining 10 KSU in Q4 completes the design. Happy to share the detailed cost breakdown.

Top-up reason field (under 50 words):

Production simulations for a paper I am preparing for journal submission cost more per replication than the pilot-scaled estimate, exhausting the Q3 grant mid-study. Measured cost is about 4 SU per replication; 20 KSU across Q3 and Q4 completes the design, restarting this quarter rather than stalling until October.
