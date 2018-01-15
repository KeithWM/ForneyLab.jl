# This file implements:
#   - LinkedList: a linked list datastructure used by DependencyGraph.
#   - DependencyGraph: a leightweight adjacency-list based directed graph datastructure.
#   - children: a DFS-like algorithm to find all children of a set of vertices in a DependencyGraph.

# DependencyGraph is used as an intermediate datastructure by ForneyLab's message scheduling algorithms.
# The general recipe for building a message scheduling involves at least two steps:
#   1. Build a DependencyGraph (DG) based on a FactorGraph.
#      The vertices in the DG are (for example) node interfaces.
#      An edge v -> w in the DG denotes that the message out of interface v depends on the message out of w.
#   2. Invoke the children algorithm on the DG to find a valid sequential message passing schedule.

###############################
# Linked list datastructure
###############################

type LinkedListElement{T}
    payload::T
    next::LinkedListElement{T}

    LinkedListElement{T}(payload::T) = new{T}(payload)
end

LinkedListElement{T}(payload::T) = LinkedListElement{T}(payload)

type LinkedList{T}
    first::LinkedListElement{T}
    last::LinkedListElement{T}

    LinkedList() = new{T}()
end

function Base.push!(list::LinkedList, payload)
    if isdefined(list, :first)
        list.last.next = LinkedListElement(payload)
        list.last = list.last.next
    else
        list.first = list.last = LinkedListElement(payload)
    end

    return list
end

Base.isempty(list::LinkedList) = !isdefined(list, :first)

function Base.collect{T}(list::LinkedList{T})
    items = T[]
    if isdefined(list, :first)
        entry = list.first
        while isdefined(entry, :next)
            push!(items, entry.payload)
            entry = entry.next
        end
        push!(items, entry.payload) # last entry
    end

    return items
end


###############################
# DependencyGraph
###############################

"""
A `DependencyGraph` is a directed graph in which an edge `v -> w`
represents a dependency of vertex `v` on vertex `w`.
Dependency graphs are used for example by message scheduling algorithms.
"""
type DependencyGraph{VT}
    vertices::Vector{VT}
    neighbors::Vector{LinkedList}

    DependencyGraph() = new(Vector{VT}(), Vector{LinkedList{Int}}())
end

function addVertex!{VT}(dg::DependencyGraph{VT}, v::VT)
    push!(dg.vertices, v)
    push!(dg.neighbors, LinkedList{Int}())
    return dg
end

function addEdge!{VT}(dg::DependencyGraph{VT}, from::VT, to::VT)
    v = findfirst(dg.vertices, from)
    w = findfirst(dg.vertices, to)
    push!(dg.neighbors[v], w)
    return dg
end

neighbors(vertex_idx::Int, dg::DependencyGraph) = collect(dg.neighbors[vertex_idx])

function neighbors{VT}(vertex::VT, dg::DependencyGraph{VT})
    vertex_idx = findfirst(dg.vertices, vertex)
    return dg.vertices[neighbors(vertex_idx, dg)]
end

#########################################
# Graph algorithms for DependencyGraph
#########################################

"""
children(vertices, graph; allow_cycles=false, breaker_sites=[], restrict_to=[])

Return a vector consisting of `vertices` and all their children in `graph`.
`v` is a child of `u` iff there exists a path from `u` to `v`.
The resulting array is sorted in reverse topological order,
i.e. for each directed edge `u -> v`, `v` (child of `u`) appears before `u`.

Optional keyword arguments:

- `allow_cycles`: set to true to accept cycles.
- `breaker_sites`: a Set of vertices on which the search will terminate.
- `restrict_to`: a Set of vertices to restrict the search to.

This function can be used to generate message passing schedules
if `graph` is a dependency graph.
"""
function children{V}(   vertices::Vector{V},
                        graph::DependencyGraph{V};
                        allow_cycles::Bool=false,
                        breaker_sites::Set{V}=Set{V}(),
                        restrict_to::Set{V}=Set{V}())

    # Find vertex indexes of breaker_sites
    breaker_vertices = Set{Int}(map((v) -> findfirst(graph.vertices, v), breaker_sites))
    restrict_to_vertices = Set{Int}(map((v) -> findfirst(graph.vertices, v), restrict_to))

    visited = Int[] # Hold topologically sorted list of indices of child vertices

    for root in vertices
        # Iterative depth-first search
        stack = Int[findfirst(graph.vertices, root)]
        visited_from_root = Int[]
        while !isempty(stack)
            v = pop!(stack)

            # Check search restrictions
            (v in breaker_vertices) && continue
            (isempty(restrict_to_vertices) || (v in restrict_to_vertices)) || continue

            # Check if vertex v has already been visited
            (v in visited) && continue
            if v in visited_from_root
                if allow_cycles
                    continue
                else
                    throw(ArgumentError("The input graph contains a loop around $(graph.vertices[v])."))
                end
            end

            push!(visited_from_root, v) # Mark v as visited

            # Add all adjacent vertices to the stack
            for w in neighbors(v, graph)
                push!(stack, w)
            end
        end

        # Add the newly visited children to the global visited list
        visited = vcat(visited, reverse(visited_from_root))
    end

    return graph.vertices[visited] # Return actual vertices instead of their indexes
end

children{V}(vertex::V, graph::DependencyGraph{V}; kwargs...) = children(V[vertex], graph; kwargs...)