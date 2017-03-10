include("utils.jl");

using utils;

import Base: ==;

typealias Action String;

typealias Percept Tuple{Any, Any};

type Problem <: AbstractProblem
    initial::String
    goal::Nullable{String}

    function Problem(initial_state::String; goal_state::Union{Void, String}=nothing)
        return new(initial_state, Nullable{String}(goal_state));
    end
end

function actions{T <: AbstractProblem}(ap::T, state::String)
    println("actions() is not implemented yet for ", typeof(ap), "!");
    nothing;
end

function result{T <: AbstractProblem}(ap::T, state::String, action::Action)
    println("result() is not implemented yet for ", typeof(ap), "!");
    nothing;
end

function goal_test{T <: AbstractProblem}(ap::T, state::String)
    return ap.goal == state;
end

function path_cost{T <: AbstractProblem}(ap::T, cost::Float64, state1::String, action::Action, state2::String)
    return cost + 1;
end

function value{T <: AbstractProblem}(ap::T, state::String)
    println("value() is not implemented yet for ", typeof(ap), "!");
    nothing;
end

type Node
    state::String
    path_cost::Float64
    depth::UInt32
    action::Nullable{Action}
    parent::Nullable{Node}

    function Node(state::String; parent::Union{Void, Node}=nothing, action::Union{Void, Action}=nothing, path_cost::Float64=0.0)
        nn = new(state, path_cost, UInt32(0), Nullable{Action}(action), Nullable{Node}(parent));
        if (typeof(parent) <: Node)
            nn.depth = UInt32(parent.depth + 1);
        end
        return nn;
    end
end

function expand{T <: AbstractProblem}(n::Node, ap::T)
    return [child_node(n, ap, act) for act in actions(ap, n.state)];
end

function child_node{T <: AbstractProblem}(n::Node, ap::T, action::Action)
    local next_node = result(ap, n.state, action);
    return Node(next_node, n, action, ap.path_cost(n.path_cost, n.state, action, next_node));
end

function solution(n::Node)
    local path_sequence = path(n);
    return [node.action for node in path_sequence[2:length(path_sequence)]];
end

function path(n::Node)
    local node = n;
    local path_back = [];
    while true
        push!(path_back, node);
        if (!isnull(node.parent))
            node = node.parent;
        else     #the root node does not have a parent node
            break;
        end
    end
    path_back = reverse(path_back);
    return path_back;
end

==(n1::Node, n2::Node) = (n1.state == n2.state);

type SimpleProblemSolvingAgentProgram
    state::Nullable{String}
    goal::Nullable{String}
    seq::Array{Action, 1}
    problem::Nullable{Problem}

    function SimpleProblemSolvingAgentProgram(;initial_state::Union{Void, String}=nothing)
        return new(Nullable{String}(initial_state), Nullable{String}(), Array{Action, 1}(), Nullable{Problem}());
    end
end

function execute{T <: SimpleProblemSolvingAgentProgram}(spsap::T, percept::Percept)
    spsap.state = update_state(spsap, spsap.state, percept);
    if (length(spsap.seq) == 0)
        spsap.goal = formulate_problem(spsap, spsap.state);
        spsap.problem = forumate_problem(spsap, spsap.state, spsap.goal);
        spsap.seq = search(spsap, spsap.problem);
        if (length(spsap.seq) == 0)
            return Void;
        end
    end
    local action = shift!(spsap.seq);
    return action;
end

function update_state{T <: SimpleProblemSolvingAgentProgram}(spsap::T, state::String, percept::Percept)
    println("update_state() is not implemented yet for ", typeof(spsap), "!");
    nothing;
end

function formulate_goal{T <: SimpleProblemSolvingAgentProgram}(spsap::T, state::String)
    println("formulate_goal() is not implemented yet for ", typeof(spsap), "!");
    nothing;
end

function formulate_problem{T <: SimpleProblemSolvingAgentProgram}(spsap::T, state::String, goal::String)
    println("formulate_problem() is not implemented yet for ", typeof(spsap), "!");
    nothing;
end

function search{T <: SimpleProblemSolvingAgentProgram}(spsap::T, problem::Problem)
    println("search() is not implemented yet for ", typeof(spsap), "!");
    nothing;
end

type GAState
    genes::Array{Any, 1}

    function GAState(genes::Array{Any, 1})
        return new(Array{Any,1}(deepcopy(genes)));
    end
end

function mate{T <: GAState}(ga_state::T, other::T)
    local c = rand(RandomDevice(), range(1, length(ga_state.genes)));
    local new_ga_state = deepcopy(ga_state[1:c]);
    for element in other.genes[(c + 1):length(other.genes)]
        push!(new_ga_state, element);
    end
    return new_ga_state;
end

function mutate{T <: GAState}(ga_state::T)
    println("mutate() is not implemented yet for ", typeof(ga_state), "!");
    nothing;
end

"""
    tree_search{T1 <: AbstractProblem, T2 <: Queue}(problem::T1, frontier::T2)

Search the given problem by using the general tree search algorithm (Fig. 3.7).
"""
function tree_search{T1 <: AbstractProblem, T2 <: Queue}(problem::T1, frontier::T2)
    push!(frontier, Node(problem.initial));
    while (length(frontier) != 0)
        local node = pop!(frontier);
        if (goal_test(problem, node.state))
            return node;
        end
        extend!(frontier, expand(node, problem));
    end
    return nothing;
end

"""
    graph_search{T1 <: AbstractProblem, T2 <: Queue}(problem::T1, frontier::T2)

Search the given problem by using the general graph search algorithm (Fig. 3.7).

The uniform cost algorithm (Fig. 3.14) should be used when the frontier is a priority queue.
"""
function graph_search{T1 <: AbstractProblem, T2 <: Queue}(problem::T1, frontier::T2)
    local explored = Set{String}();
    push!(frontier, Node(problem.initial));
    while (length(frontier) != 0)
        local node = pop!(frontier);
        if (goal_test(problem, node.state))
            return node;
        end
        push!(explored, node.state);
        extend!(frontier, collect(child_node for child_node in expand(node, problem)
                                if (!(child_node.state in explored) && !(child_node in frontier))));
    end
    return nothing;
end

function breadth_first_tree_search{T <: AbstractProblem}(problem::T)
    return tree_search(problem, FIFOQueue());
end

function depth_first_tree_search{T <: AbstractProblem}(problem::T)
    return tree_search(problem, Stack());
end

function depth_first_graph_search{T <: AbstractProblem}(problem::T)
    return graph_search(problem, Stack());
end

function breadth_first_search{T <: AbstractProblem}(problem::T)
    local node = Node(problem.initial);
    if (goal_test(problem, node.state))
        return node;
    end
    local frontier = FIFOQueue();
    push!(frontier, node);
    local explored = Set{String}();
    while (length(frontier) != 0)
        node = pop!(frontier);
        push!(explored, node.state);
        for child_node in expand(node, problem)
            if (!(child_node.state in explored) && !(child_node in frontier))
                if (goal_test(problem, child_node.state))
                    return child_node;
                end
                push!(frontier, child_node);
            end
        end
    end
    return nothing;
end

function best_first_graph_search{T <: AbstractProblem}(problem::T, f::Function)
    local mf = MemoizedFunction(f);
    local node = Node(problem.initial);
    if (goal_state(problem, node.state))
        return node;
    end
    local frontier = PriorityQueue();
    push!(frontier, node, mf);
    local explored = Set{String}();
    while (length(frontier) != 0)
        node = pop!(frontier);
        if (goal_state(problem, node.state))
            return node;
        end
        push!(explored, node.state);
        for child_node in expand(node, problem)
            if (!(child_node.state in explored) &&
                !(child_node in collect(getindex(x, 2) for x in frontier.array)))
                push!(frontier, child_node, mf);
            elseif (child_node in [getindex(x, 2) for x in frontier.array])
            #Recall that Nodes can share the same state and different values for other fields.
                local existing_node = pop!(collect(getindex(x, 2)
                                                    for x in frontier.array
                                                    if (getindex(x, 2) == child_node)));
                if (eval_memoized_function(mf, child_node) < eval_memoized_function(mf, existing_node))
                    delete!(frontier, existing_node);
                    push!(frontier, child_node, mf);
                end
            end
        end
    end
    return nothing;
end

function uniform_cost_search{T <: AbstractProblem}(problem::T)
    return best_first_graph_search(problem, (function(n::Node)return n.path_cost;end));
end

function recursive_dls{T <: AbstractProblem}(node::Node, problem::T, limit::Int64)
    if (goal_test(problem, node.state))
        return node;
    elseif (node.depth == limit)
        return "cutoff";
    else
        local cutoff_occurred = false;
        for child_node in expand(node, problem)
            local result = recursive_dls(child_node, problem, limit);
            if (result == "cutoff")
                cutoff_occurred = true;
            elseif (!(typeof(result <: Void)))
                return result;
            end
        end
        return if_(cutoff_occurred, "cutoff", nothing);
    end
end;

function depth_limited_search{T <: AbstractProblem}(problem::T; limit::Int64=0)
    return recursive_dls(Node(problem.initial), problem, limit);
end

function iterative_deepening_search{T <: AbstractProblem}(problem::T)
    for depth in 1:typemax(Int64)
        local result = depth_limited_search(problem, depth)
        if (result != "cutoff")
            return result;
        end
    end
    return nothing;
end

const greedy_best_first_graph_search = best_first_graph_search;

type Graph
    dict::Dict{Any, Any}
    locations::Dict{String, Tuple{Any, Any}}
    directed::Bool

    function Graph{T <: Dict}(;dict::Union{Void, T}=nothing, locations::Union{Void, Dict{String, Tuple{Any, Any}}}=nothing, directed::Bool=true)
        local ng::Graph;
        if ((typeof(dict) <: Void) && (typeof(locations) <: Void))
            ng = new(Dict{Any, Any}(), Dict{String, Tuple{Any, Any}}(), Bool(directed));
        else
            ng = new(Dict{Any, Any}(dict), Dict{String, Tuple{Any, Any}}(locations), Bool(directed));
        end
        if (!ng.directed)
            make_undirected(ng);
        end
        return ng;
    end

    function Graph(graph::Graph)
        return new(Dict{Any, Any}(graph.dict), Dict{String, Tuple{Any, Any}}(graph.locations), Bool(graph.directed));
    end
end

function make_undirected(graph::Graph)
    for location_A in keys(graph.dict)
        for (location_B, d) in graph.dict[location_A]
            connect_nodes(graph, location_B, location_A, distance=d);
        end
    end
end

function connect_nodes(graph::Graph, A::String, B::String; distance::Int64=Int64(1))
    get!(graph.dict, A, Dict{String, Int64}())[B]=distance;
    if (!graph.directed)
        get!(graph.dict, B, Dict{String, Int64}())[A]=distance;
    end
    nothing;
end

function get_linked_nodes(graph::Graph, a::String; b::Union{Void, String}=nothing)
    local linked = get!(graph.dict, A, Dict{Any, Any}());
    if (typeof(b) <: Void)
        return linked;
    else
        return linked[b];
    end
end

function get_nodes(graph::Graph)
    return collect(keys(graph.dict));
end

function UndirectedGraph{T <: Dict}(dict::T, locations::Dict{String, Tuple{Any, Any}})
    return Graph(dict=dict, locations=locations, directed=false);
end

function UndirectedGraph()
    return Graph(directed=false);
end

type GraphProblem <: AbstractProblem
    initial::String
    goal::Nullable{String}
    graph::Graph
    itg::MemoizedFunction


    function GraphProblem(initial_state::String, goal_state::String, graph::Graph)
        return new(initial_state, Nullable{String}(goal_state), Graph(graph), MemoizedFunction(initial_to_goal_distance));
    end
end

function get_actions(gp::GraphProblem, loc::String)
    return collect(keys(gp.graph[loc]));
end

function get_result(gp::GraphProblem, state::String, action::Action)
    return action;
end

function path_cost(gp::GraphProblem, current_cost::Float64, location_A::String, action::Action, location_B::String)
    local AB_distance::Float64;
    if (haskey(gp.dict, A) && haskey(gp.dict[A], B))
        AB_distance= Float64(gp.graph.get_linked_nodes(A,B));
    else
        AB_distance = Float64(Inf);
    end
    return current_cost + AB_distance;
end

"""
    initial_to_goal_distance(gp::GraphProblem, n::Node)

Compute the straight line distance between the initial state and goal state.
"""
function initial_to_goal_distance(gp::GraphProblem, n::Node)
    local locations = gp.graph.locations;
    if (isnull(locations))
        return Inf;
    else
        return Int64(floor(distance(locations[node.state], locations[gp.goal])));
    end
end

function astar_search(problem::GraphProblem; h::Union{Void, Function}=nothing)
    local mh::MemoizedFunction; #memoized h(n) function
    local problem_type = typeof(problem);
    if (!(typeof(h) <: Void))
        mh = MemoizedFunction(h);
    else
        mh = problem.itg;
    end
    return best_first_graph_search(problem,
                                    (function(prob::GraphProblem, node::Node; h::MemoizedFunction=mh)
                                        return n.path_cost + eval_memoized_function(h, prob, node);end));
end

romania = UndirectedGraph(Dict(
                            Pair("A", Dict("Z"=>75, "S"=>140, "T"=>118)),
                            Pair("B", Dict("U"=>85, "P"=>101, "G"=>90, "F"=>211)),
                            Pair("C", Dict("D"=>120, "R"=>146, "P"=>138)),
                            Pair("D", Dict("M"=>75)),
                            Pair("E", Dict("H"=>86)),
                            Pair("F", Dict("S"=>99)),
                            Pair("H", Dict("U"=>98)),
                            Pair("I", Dict("V"=>92, "N"=>87)),
                            Pair("L", Dict("T"=>111, "M"=>70)),
                            Pair("O", Dict("Z"=>71, "S"=>151)),
                            Pair("P", Dict("R"=>97)),
                            Pair("R", Dict("S"=>80)),
                            Pair("U", Dict("V"=>142)),
                                ),
                            Dict{String, Tuple{Any, Any}}(
                                "A"=>( 91, 492), "B"=>(400, 327), "C"=>(253, 288), "D"=>(165, 299),
                                "E"=>(562, 293), "F"=>(305, 449), "G"=>(375, 270), "H"=>(534, 350),
                                "I"=>(473, 506), "L"=>(165, 379), "M"=>(168, 339), "N"=>(406, 537),
                                "O"=>(131, 571), "P"=>(320, 368), "R"=>(233, 410), "S"=>(207, 457),
                                "T"=>( 94, 410), "U"=>(456, 350), "V"=>(509, 444), "Z"=>(108, 531),
                                )
                            );
