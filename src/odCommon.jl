
module odCommon

include("agent.jl")

using ColorSchemes, Colors
using Glob
using LightGraphs

"""
    function make_graph(n=20, p=0.2)

Create and return a random connected Erdos-Renyi graph with ``n`` nodes and
probability ``p`` that any two nodes are neighbors.
"""
function make_graph(n=20, p=0.2)
    rm.(glob("graph*.svg"))
    #makes sure the random erdos renyi graph is connected
    graph = erdos_renyi(n,p)
    while is_connected(graph) == false
        graph = erdos_renyi(n,p)
    end

    return graph
end


"""
    function set_opinion(graph, node_list, agent_list, random_influencer::Bool,
    replacement::Bool)

Choose an agent at random from the environment, and change its (or one of its randomly chosen graph neighbor's) opinion to match the neighbor (or agent).

# Arguments

- `graph`, `node_list`, `agent_list`: the current state of the simulation, as embodied in the graph and agent states.

- `random_influencer`: if `true`, the randomly-chosen agent will influence (change the opinion of) its randomly-chosen graph neighbor. Otherwise, the neighbor will change it.

- `replacement`: if `true`, puts back the last randomly selected node in the list of next nodes that can be selected. If `false`, takes out the last randomly selected node from the list of next nodes that can be selected.
"""
function set_opinion(graph, node_list, agent_list, random_influencer::Bool,
    replacement::Bool)

    #picks a randomly selected node, and finds the corresponding agent
    this_node = rand(node_list)
    this_agent = agent_list[this_node]
    #picks a randomly selected neighbor of this node, and finds the corresponding agent
    neighbor_list = neighbors(graph, this_node)
    next_node = rand(neighbor_list)
    next_agent = agent_list[next_node]
    #sets the orginial node's opinion to the neighbor node's opinion
    if random_influencer
        next_opinion = getOpinions(this_agent)[1]
        setOpinion(next_agent, next_opinion, 1)
    else
        next_opinion = getOpinions(next_agent)[1]
        setOpinion(this_agent, next_opinion, 1)
    end
    if replacement==false
        #takes the last node that was selected out of the list of next nodes to be selected
        filter!(x -> x ≠ this_node, node_list)
    end
end


# Create one .svg file for the current frame of the graph animation.
# FIX: remember_layout no longer being rememberd?
function draw_graph_frame(graph, agent_list, iter)
    locs_x, locs_y = spring_layout(graph)
    # remember and reuse graph layout for each animation frame
    remember_layout = x -> spring_layout(x, locs_x, locs_y)
    # plot this frame of animation to a file
    graphp = gplot(graph,
        layout=remember_layout,
        NODESIZE=.08,
        nodestrokec=colorant"grey",
        nodestrokelw=.5,
        nodefillc=[ ifelse(a.opinion==Blue::Opinion,colorant"blue",
            colorant"red") for a in agent_list ])
    draw(SVG("$(store_dir)/graph$(lpad(string(iter),3,'0')).svg"),
        graphp)
    run(`mogrify -format svg -gravity South -pointsize 15 -annotate 0
        "Iteration $(iter) "
        "$(store_dir)/graph"$(lpad(string(iter),3,'0')).svg`)
end

end # module odCommon
