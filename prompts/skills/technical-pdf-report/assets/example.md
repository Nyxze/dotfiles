---
title: Service performance report
subtitle: Measurements, observations, and decisions
document_type: Technical report
author: Example Author
group: Platform team
date: 6 November 2026
footer: Example service · Technical report
lang: en
---

# Summary

The measured service remained stable under the tested load. This example demonstrates the report's typography and page structure; its figures are illustrative.

| Metric | Observation | Decision |
|---|---:|---|
| Median response | 24 ms | Retain the current configuration |
| Error rate | 0% | Continue monitoring |

# 1 — Method {: .page-start }

## 1.1 Scope

The trial used a fixed workload and the same machine for every run. Record the setup, the exact query or request, and the limits of the comparison before presenting a result.

### Figure 1: Example execution trace

```text
Request       GET /items?limit=20
Status        200
Duration      24 ms
Rows returned 20
```

# 2 — Results

## 2.1 Comparison

| Variant | Trial 1 | Trial 2 | Trial 3 | Median |
|---|---:|---:|---:|---:|
| Baseline | 31 ms | 29 ms | 30 ms | 30 ms |
| Candidate | 25 ms | 24 ms | 23 ms | 24 ms |

The observed median changed by 6 ms in this illustrative example. State what the numbers support and any uncertainty that remains.

# Conclusion

Keep conclusions short and link each decision to the evidence shown in the report.
