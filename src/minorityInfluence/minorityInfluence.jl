
module minorityInfluence

function new_run_sim(;n=20, p=0.2, num_opinions=2, make_anim=false, influencer=false)
    save_dir = pwd()
    #none of the old nodes can be selected until all of the new nodes are selected because of cognitive rebalancing
    replacement=false
    graph = make_graph(n, p)
    node_list = Array(vertices(graph))
    n = nv(graph)
    #makes a list of agents with two randomly assigned opinions - each opinion can be red or blue
    agent_list = []
    opin_list = (Red::Opinion, Blue::Opinion)
    #are either opinion in each attribute as likely to happen as the other?
    for n in node_list
        this_agent = Agent()
        push!(agent_list, this_agent)
    end
    uniform = false
    iter = 1
    #println("Iterations:")
    #the percent of agents with the red opinion for attribute 1 and attribute 2
    percent_red_list_1 = []
    percent_red_list_2 = []
    use_node_list = copy(node_list)
    #the percent of agents that are interally consistent for each iteration
    percent_consistent_list = []
    percent_consistent_list_acr = []

    while uniform == false
        #saves the percent of agents with red opinion for attribute 1 and attribute 2 in each iteration
        num_red_1 = count_opinions(agent_list, Red, 1)
        percent_red_1 = num_red_1/n
        push!(percent_red_list_1, percent_red_1)
        num_red_2 = count_opinions(agent_list, Red, 2)
        percent_red_2 = num_red_2/n
        push!(percent_red_list_2, percent_red_2)
        push!(percent_consistent_list, sum(isConsistent(a) for a in agent_list)/length(agent_list))
        if iter % 40 > 0
            print(".")
        else
            println(iter)
        end

        if make_anim
            make_graph_anim(graph, agent_list, iter)
        end

        #checks to see if we should stop the sim
        uniform = reached_stopping_condition(agent_list, node_list, graph, iter)
        if uniform == true
            #println(percent_red_list_1)
            #println(percent_red_list_2)
        end
        #each agent does cognitive rebalancing when there are no new agents left
        if replacement == false && length(use_node_list) == 0
            #println("cognitive rebalance!")
            for a in agent_list
                cognitive_rebalance(a)
            end
            use_node_list = copy(node_list)
        end
        push!(percent_consistent_list_acr, sum(isConsistent(a) for a in agent_list)/length(agent_list))
        #changes the opinion of an agent based on the parameters
        new_set_opinion(graph, use_node_list, agent_list, replacement, influencer)
        iter += 1
    end
    println(iter)
    #saves and shows a plot of the percent of agents with red opinion for each iteration
    display(Plots.plot(1:length(percent_red_list_1),percent_red_list_1, title="percent red opinion of attribute 1 for each iteration", xlabel="number of iterations",ylabel="percent red opinion",seriescolor = :red))
    savefig("per_red_1_plot.png")
    display(Plots.plot(1:length(percent_red_list_2),percent_red_list_2, title="percent red opinion of attribute 2 for each iteration", xlabel="number of iterations",ylabel="percent red opinion",seriescolor = :red))
    savefig("per_red_2_plot.png")
    display(Plots.plot(1:length(percent_consistent_list),percent_consistent_list, title="percent consistent agents for each iterations", xlabel="number of iterations",ylabel="percent consistent",seriescolor = :black))
    savefig("per_const_plot.png")
    display(Plots.plot(1:length(percent_consistent_list_acr),percent_consistent_list_acr, title="percent consistent agents for each iterations (ACR)", xlabel="number of iterations",ylabel="percent consistent",seriescolor = :black))
    savefig("per_const_plot_acr.png")
    if make_anim
        println("Building animation...")
        run(`convert -delay 15 graph*.svg graph.gif`)
        println("...animation in $(tempdir())/graph.gif.")
    end

    #return to user's original directory
    cd(save_dir)
    return iter
end

function new_set_opinion(graph, node_list, agent_list, random_influencer::Bool,
    replacement::Bool)
    replacement = false
    #picks a randomly selected attribute
    this_attribute = rand([1,2])
    if this_attribute == 1
        other_attribute = 2
    else
        other_attribute = 1
    end
    #picks a randomly selected node, and finds the corresponding agent
    this_node = rand(node_list)
    this_agent = agent_list[this_node]
    #picks a randomly selected neighbor of this node, and finds the corresponding agent
    neighbor_list = neighbors(graph, this_node)
    next_node = rand(neighbor_list)
    next_agent = agent_list[next_node]
    #finds the original node's opinion of the chosen attribute
    this_opinion = getOpinions(this_agent)[this_attribute]
    #finds the neighbor node's opinion of the chosen attribute
    next_opinion = getOpinions(next_agent)[this_attribute]
    #checks if the two node's opinions of that attribute are different
    if this_opinion != next_opinion
        #checks if the majority of the node's neighbors has the opinion of the neighbor node
        num_neighbors_agree = 0
        for i in neighbor_list
            if getOpinions(agent_list[i])[this_attribute] == next_opinion
                num_neighbors_agree += 1
            end
        end
        if num_neighbors_agree/length(neighbor_list) >= 0.5
            if random_influencer
                setOpinion(next_agent, this_opinion, this_attribute)
            else
                setOpinion(this_agent, next_opinion, this_attribute)
            end
        else
            #checks if the neighbor node has the same opinion for both of its attributes
            if getOpinions(next_agent)[this_attribute] == getOpinions(next_agent)[other_attribute]
                if random_influencer
                    setOpinion(next_agent, this_opinion, this_attribute)
                else
                    setOpinion(this_agent, next_opinion, this_attribute)
                end
            end
        end
    end

    #even if a node's opinion is not changed we still take it out of the list of next nodes
    if replacement==false
        #takes the last node that was selected out of the list of next nodes to be selected
        filter!(x -> x ≠ this_node, node_list)
    end
end

function cognitive_rebalance(this_agent)
    this_attribute = rand([1,2])
    if this_attribute == 1
        other_attribute = 2
    else
        other_attribute = 1
    end
    if getOpinions(this_agent)[this_attribute] != getOpinions(this_agent)[other_attribute]
        next_opinion = getOpinions(this_agent)[other_attribute]
        setOpinion(this_agent, next_opinion, this_attribute)
    end
end

function reached_stopping_condition(agent_list, node_list, graph, iter)
    uniform = true
    n = length(agent_list)
    for i in 1:n-1
        #checks to see if all agents have the same set of opinions
        if getOpinions(agent_list[i]) != getOpinions(agent_list[i+1])
            uniform = false
            break
        elseif iter == 10000
            uniform = false
            break
        #else - checks to see if the majority of the neighbors of each agent have the same opinions as that agent
        else
            num_neighbors_agree = 0
            for x in node_list
                neighbor_list = neighbors(graph, x)
                for y in neighbor_list
                    if getOpinions(agent_list[y])[1] == getOpinions(agent_list[x])[1] && getOpinions(agent_list[y])[2] == getOpinions(agent_list[x])[2]
                        num_neighbors_agree += 1
                    end
                end
                if num_neighbors_agree/length(neighbor_list) < 0.5
                    uniform = false
                    break
                end
            end
        end
    end
    return uniform
end

end # module minorityInfluence
