
# The Binary Voter Model, commonly ascribed to (Clifford & Sudbury 1973) and
# (Holley & Liggett 1975).
#
# Clifford, P., & Sudbury, A. (1973). A Model for Spatial Conflict. Biometrika,
# 60(3), 581–588. https://doi.org/10.2307/2335008
#
# Holley, R. A., & Liggett, T. M. (1975). Ergodic theorems for weakly
# interacting infinite systems and the voter model. The Annals of Probability,
# 643–663. http://dx.doi.org/10.1214/aop/1176996306
#
# Important: on Ubuntu, you must install *inkscape* as well as ImageMagick for
# animated images to be created!   sudo apt-get install inkscape

module bvm

# General opinion-dynamics-related functions. 
include("../odCommon.jl")

using .odCommon

export run_sim, run_sims, param_sweep, conf_int_sweep

# FIX: some of these are likely not needed after refactoring to odCommon.
using LightGraphs
using GraphPlot, Compose
using ColorSchemes, Colors
using Random
using Glob
using Plots
using DataFrames
using Bootstrap
using Gadfly
using Statistics


# In the BVM, there are only two possible opinions; call them Red and Blue.
#@enum Opinion Red Blue


"""
    function run_sim(n::Integer=20, p::Float64=0.2,
        influencer::Bool=false, replacement::Bool=false;
        verbose::Bool=true, make_plots::Bool=true, make_anim::Bool=false)

Run a single simulation of the Binary Voter Model on a randomly-generated
graph. Continue until convergence (uniformity of opinion) is reached.

# Arguments

- `n`, `p`: Parameters to the [Erdos-Renyi random graph model](https://en.wikipedia.org/wiki/Erd%C5%91s%E2%80%93R%C3%A9nyi_model) (`n` = number of nodes, `p` = probability of each pair of nodes being adjacent.)

- `influencer` if `true`, makes the randomly selected node change the opinion of its randomly selected neighbor. If `false`, makes its randomly selected neighbor change the opinion of the randomly selected node

- `replacement`: if `true`, puts back the last randomly selected node in the list of next nodes that can be selected. If `false`, takes out the last randomly selected node from the list of next nodes that can be selected.

- `fixed_iters`: if `true`, run simulation for exactly `num_iters` iterations. If `false` (the default), run until all agents have the same opinion.

- `num_iters`: meaningful only if `fixed_iters` is `true`.

- `verbose`: if `true`, print output showing progress of simulation.

- `make_plots`: if `true`, saves a time series plot of the simulation.

- `make_anim`: if `true`, saves an animated gif of the simulation.

# Returns
a tuple of values:
- a status message (`String`)
- a DataFrame of results with columns:
  - `:iter`: Iteration number
  - `:frac_red`: The fraction of nodes that had the Red opinion
"""
function run_sim(n::Integer=20, p::Float64=0.2,
    influencer::Bool=false, replacement::Bool=false;
    fixed_iters::Bool=false, num_iters::Integer=500,
    verbose::Bool=true, make_plots::Bool=true, make_anim::Bool=false)

    graph = odCommon.make_graph(n, p)
    node_list = Array(vertices(graph))
    n = nv(graph)
    #makes a list of agents with randomly assigned opinions, each agent corresponds with a node
    agent_list = []
    opin_list = (odCommon.Red::odCommon.Opinion, odCommon.Blue::odCommon.Opinion)
    for n in node_list
        this_opinion = rand(opin_list)
        push!(agent_list, odCommon.Agent(this_opinion))
    end
    uniform = false
    iter = 1
    if verbose println("Iterations:") end
    percent_red_list = []
    use_node_list = copy(node_list)
    use_agent_list = copy(agent_list)

    #runs the sim until the all agents have one opinion
    while (fixed_iters && iter <= num_iters) ||
        (!fixed_iters && uniform == false)
        #saves the percent of agents with red opinion for each iteration
        num_red = count_opinions(agent_list, odCommon.Red)
        percent_red = num_red/n
        push!(percent_red_list, percent_red)
        if verbose
            if iter % 40 > 0
                print(".")
            else
                println(iter)
            end
        end

        if make_anim
            odCommon.draw_graph_frame(graph, agent_list, iter)
        end
        #checks to see if all agents have one opinion yet, if not continue sim
        uniform = true
        for i in 1:n-1
            if odCommon.getOpinions(agent_list[i]) != odCommon.getOpinions(agent_list[i+1])
                uniform = false
                break
            end
        end
        #changes the opinion of an agent based on the parameters
        if replacement == false && length(use_node_list) == 0
                use_node_list = copy(node_list)
                use_agent_list = copy(agent_list)
        end
        odCommon.set_opinion(graph, use_node_list, use_agent_list, replacement,
            influencer)
        iter += 1
    end
    if verbose println(iter) end
    #saves and shows a plot of the percent of agents with red opinion for each iteration
    if make_plots
        savefig("per_red_plot.svg")
        display(Plots.plot(
            1:length(percent_red_list),
            percent_red_list,
            title="percent red opinion for each iteration",
            xlabel="number of iterations",
            ylabel="percent red opinion",
            seriescolor = :red)
        )
    end
    if make_anim
        if verbose println("Building animation...") end
        # Important: on Ubuntu, you must install *inkscape* as well as
        # ImageMagick for this to work!
        run(`convert -size 800X600 -delay 15 graph*.svg graph.gif`)
        if verbose println("...animation in graph.gif.") end
    end

    return ("Completed $(length(percent_red_list)) iterations.",
        DataFrame(:iter => 1:length(percent_red_list),
            :frac_red => percent_red_list)
    )
end


function run_sims(num_trials::Integer=10, n::Integer=20, p::Float64=0.2,
    influencer::Bool=false, replacement::Bool=false;
    fixed_iters::Bool=false, num_iters::Integer=500,
    verbose::Bool=false, make_plots::Bool=true)

    raw_results = [ run_sim(n, p, influencer, replacement; verbose=verbose,
        fixed_iters=fixed_iters, num_iters=num_iters,
        make_anim=false, make_plots=make_plots)[2] for i in 1:num_trials]
    return "Completed $num_trials trials.", 
        rename(
            reduce(vcat, [ hcat(r,repeat([i],nrow(r)),copycols=false)
                    for (i, r) in enumerate(raw_results) ]),
            :x1=>:trial)
end


"""
    function param_sweep(num_trials=10, this_n=20, this_p=0.2,
        influencer=false, replacement=false)

Run two entire parameter sweeps of simulations, one for varying values of `n` (number of nodes in random graph) and the other for varying values of `p` (edge probability). Plot output will be created in the files `n_list_plot.svg` and `p_list_plot.svg`.

# Arguments

- `num_trials`: the number of trials for each fixed combination of parameters.

- `make_anim`: if `true`, saves an animated gif of the simulation.

- `this_n`: value of `n` that will be constant as `p` is iterated.

- `this_p`: value of `p` that will be constant as `n` is iterated.

- `influencer`, `replacement`: passed to [`run_sim()`](@ref run_sim) (see notes there).

# Returns
- nothing
"""
function param_sweep(num_trials=10, this_n=20, this_p=0.2, influencer=false, replacement=false)
    n_list = []
    p_list = []
    n_steps_list = []
    p_steps_list = []
    #iterate through n, constant p
    for n in 10:10:100
        #save the num of steps for that val of n for each sim
        for x in 1:num_trials
            num_steps = run_sim(n, this_p, false, influencer, replacement)
            push!(n_list, n)
            push!(n_steps_list, num_steps)
        end
    end
    #iterate through p, constant n
    for p in 0.1:0.1:1.0
        #save the num of steps for that val of p for each sim
        for x in 1:num_trials
            num_steps = run_sim(this_n, p, false, influencer, replacement)
            push!(p_list, p)
            push!(p_steps_list, num_steps)
        end
    end
    #generate dataframe and graph the plot of vals of n and num of steps
    n_data = DataFrame(N = n_list, STEPS = n_steps_list)
    showall(n_data)
    display(Plots.plot(n_list, n_steps_list, seriestype=:scatter, title= "number of nodes vs number of steps", xlabel="number of nodes", ylabel="number of steps", label="influencer = $(influencer), replacement = $(replacement)"))
    savefig("n_list_plot.svg")
    #generate dataframe and graph the plot of vals of p and num of steps
    p_data = DataFrame(P = p_list, STEPS = p_steps_list)
    showall(p_data)
    display(Plots.plot(p_list, p_steps_list, seriestype=:scatter, title= "probability of neighbor vs number of steps", xlabel="probability of neighbor", ylabel="number of steps", label="influencer = $(influencer), replacement = $(replacement)"))
    savefig("p_list_plot.svg")
end


"""
    function conf_int_sweep(num_trials=10, n=20, influencer=false,
        replacement=false)

Run a suite of simulations for varying values of `p` (probability of edge in random graph), and plot λ (\$=N×p\$) vs. num-iterations-to-converge with a 95% confidence band. The plot will be stored in `sweep`_n_`.svg`.

# Arguments

- `num_trials`: the number of trials for each value of `p` (and λ).

- `n`: the number of nodes in the random graph.

- `influencer`, `replacement`: passed to [`run_sim()`](@ref run_sim) (see notes there).

# Returns
- nothing
"""
function conf_int_sweep(num_trials=10, n=20, influencer=false, replacement=false)
    x_vals_list = []
    num_step_list = []
    mean_step_list = []
    min_step_list = []
    max_step_list = []
    #iterate through p, constant n
    for p in 0.1:0.1:1.0
        #save the num of steps for that val of x = n*p for each sim
        for i in 1:num_trials
            num_steps = run_sim(n, p, false, influencer, replacement)
            push!(num_step_list, num_steps)
        end
        #finds the min, mean, and max of the confidence interval for that val of x
        bs = bootstrap(mean, num_step_list, BasicSampling(length(num_step_list)))
        c = confint(bs, BasicConfInt(0.95));[1]
        ci = c[1]
        m = ci[1]
        min = ci[2]
        max = ci[3]
        #lambda = n*p
        x = n*p
        #saves the x, min, mean, and max of that confidence interval to lists
        push!(mean_step_list, m)
        push!(min_step_list, min)
        push!(max_step_list, max)
        push!(x_vals_list, x)
    end
    #generates dataframe of the min, mean, and max of the confidence interval for each val of x
    df = DataFrame(mean=mean_step_list, min=min_step_list, max=max_step_list, xval=x_vals_list)
    show(df, allrows=true, allcols=true)
    layers = Layer[]
    #the colors of the layers aren't that bad but can we find some pretty colors?
    mean_layer = layer(df, x=:xval, y=:mean, Geom.line, Theme(default_color=colorant"red"))
    min_layer = layer(df, x=:xval, y=:min, Geom.line, Theme(default_color=colorant"pink"))
    max_layer = layer(df, x=:xval, y=:max, Geom.line, Theme(default_color=colorant"pink"))
    fill_layer = layer(df, x=:xval, ymin=:min, ymax=:max, Geom.ribbon, Theme(default_color=colorant"yellow"))
    append!(layers, mean_layer)
    append!(layers, min_layer)
    append!(layers, max_layer)
    append!(layers, fill_layer)
    #plots the num of steps for the graph to converge for different vals of lambda with the confidence interval
    #how can we add a legend that looks like influencer = $(influencer), replacement = $(replacement)?
    p = Gadfly.plot(df, layers, Guide.xlabel("Value of Lambda"), Guide.ylabel("Number of Iterations"), Guide.title("Iterations until Convergence by Lambda"))
    draw(SVG("sweep$(n).svg"), p)
end


"""
    function count_opinions(agent_list, o::Opinion, x::Int)

Return the number of agents who hold opinion `o`.

# Arguments

- `x`: FIX ??

"""
function count_opinions(agent_list, o::odCommon.Opinion, x::Int=1)
    num_with_opinion = 0
    for a in agent_list
        if odCommon.getOpinions(a)[x] == o
            num_with_opinion += 1
        end
    end
    return num_with_opinion
end

end # module bvm
