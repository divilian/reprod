
## Binary Voter Model

A simulation to reproduce the original Binary Voter Model of Clifford and
Sudbury 1973[^1] and Holley and Liggett 1975[^2].

```@meta
CurrentModule = bvm
```

```@docs
run_sim(n=20, p=0.2, influencer=false, replacement=false; verbose=true, make_anim=false)
param_sweep(num_runs=10, this_n=20, this_p=0.2, influencer=false, replacement=false)
conf_int_sweep(num_trials=10, this_n=20, influencer=false, replacement=false)
```

# References

[^1]: Clifford, P., & Sudbury, A. (1973). A Model for Spatial Conflict. Biometrika, 60(3), 581–588. https://doi.org/10.2307/2335008
[^2]: Holley, R. A., & Liggett, T. M. (1975). Ergodic theorems for weakly interacting infinite systems and the voter model. The Annals of Probability, 643–663. http://dx.doi.org/10.1214/aop/1176996306

