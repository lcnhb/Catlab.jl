""" Diagrams in a category and their morphisms.
"""
module Diagrams
export Diagram, DiagramHom, id, op, co, shape, diagram, shape_map, diagram_map,
  ob_map, hom_map

using ...GAT
import ...Theories: Category, dom, codom, id, compose, ⋅, ∘
import ..Categories: ob_map, hom_map
using ..FinCats
using ..FinCats: mapvals

# TODO: Implement these functions more generally, and move elsewhere.

""" Opposite of a category or, more generally, 1-cell dual of a 2-category.
"""
function op end

""" 2-cell dual of a 2-category.
"""
function co end

# Data types
############

""" Diagram in a category.

Recall that a *diagram* in a category ``C`` is a functor ``D: J → C``, where for
us the *shape category* ``J`` is finitely presented. Such a diagram is captured
perfectly well by a `FinDomFunctor`, but there are several different notions of
morphism between diagrams. This simple wrapper type exists to distinguish them.
See [`DiagramHom`](@ref) for more.
"""
struct Diagram{T,D<:FinDomFunctor}
  diagram::D
end
Diagram{T}(F::D) where {T,D<:FinDomFunctor} = Diagram{T,D}(F)
Diagram{T}(d::Diagram) where T = Diagram{T}(d.diagram)
Diagram(args...) = Diagram{id}(args...)

""" Functor underlying a diagram object.
"""
diagram(d::Diagram) = d.diagram

""" The *shape* or *indexing category* of a diagram.

This is the domain of the underlying functor.
"""
shape(d::Diagram) = dom(diagram(d))

Base.:(==)(d1::Diagram{T}, d2::Diagram{S}) where {T,S} =
  T == S && diagram(d1) == diagram(d2)

""" Morphism of diagrams in a category.

In fact, this type encompasses several different kinds of morphisms from a
diagram ``D: J → C`` to another diagram ``D′: J′ → C``:

1. `DiagramHom{id}`: a functor ``F: J → J′`` together with a natural
   transformation ``ϕ: D ⇒ F⋅D′``
2. `DiagramHom{op}`: a functor ``F: J′ → J`` together with a natural
   transformation ``ϕ: F⋅D ⇒ D′``
3. `DiagramHom{co}`: a functor ``F: J → J′`` together with a natural
   transformation ``ϕ: F⋅D′ ⇒ D``.

Note that `Diagram{op}` is not the opposite category of `Diagram{id}`, but
`Diagram{op}` and `Diagram{co}` are opposites of each other. Explicit support is
included for both because they are useful for different purposes: morphisms of
type `DiagramHom{op}` induce morphisms between the limits of the diagram,
whereas morphisms of type `DiagramHom{co}` generalize morphisms of polynomial
functors.
"""
struct DiagramHom{T,F<:FinFunctor,Φ<:FinTransformation,D<:FinDomFunctor}
  shape_map::F
  diagram_map::Φ
  precomposed_diagram::D
end
DiagramHom{T}(shape_map::F, diagram_map::Φ, precomposed_diagram::D) where
    {T,F<:FinFunctor,Φ<:FinTransformation,D<:FinDomFunctor} =
  DiagramHom{T,F,Φ,D}(shape_map, diagram_map, precomposed_diagram)
DiagramHom{T}(f::DiagramHom) where T =
  DiagramHom{T}(f.shape_map, f.diagram_map, f.precomposed_diagram)
DiagramHom(args...) = DiagramHom{id}(args...)

DiagramHom{T}(ob_maps, hom_map, D::Diagram{T}, D′::Diagram{T}) where T =
  DiagramHom{T}(ob_maps, hom_map, diagram(D), diagram(D′))
DiagramHom{T}(ob_maps, D::FinDomFunctor, D′::FinDomFunctor) where T =
  DiagramHom{T}(ob_maps, nothing, D, D′)

function DiagramHom{id}(ob_maps, hom_map, D::FinDomFunctor, D′::FinDomFunctor)
  f = FinFunctor(mapvals(cell1, ob_maps), hom_map, dom(D), dom(D′))
  ϕ = FinTransformation(mapvals(x -> cell2(D,x), ob_maps), D, f⋅D′)
  DiagramHom{id}(f, ϕ, D′)
end
function DiagramHom{op}(ob_maps, hom_map, D::FinDomFunctor, D′::FinDomFunctor)
  f = FinDomFunctor(mapvals(cell1, ob_maps), hom_map, dom(D′), dom(D))
  ϕ = FinTransformation(mapvals(x -> cell2(D′,x), ob_maps), f⋅D, D′)
  DiagramHom{op}(f, ϕ, D)
end
function DiagramHom{co}(ob_maps, hom_map, D::FinDomFunctor, D′::FinDomFunctor)
  f = FinDomFunctor(mapvals(cell1, ob_maps), hom_map, dom(D), dom(D′))
  ϕ = FinTransformation(mapvals(x -> cell2(D,x), ob_maps), f⋅D′, D)
  DiagramHom{co}(f, ϕ, D′)
end

cell1(pair::Union{Pair,Tuple{Any,Any}}) = first(pair)
cell1(x) = x
cell2(D::FinDomFunctor, pair::Union{Pair,Tuple{Any,Any}}) = last(pair)
cell2(D::FinDomFunctor, x) = id(codom(D), ob_map(D, x))

shape_map(f::DiagramHom) = f.shape_map
diagram_map(f::DiagramHom) = f.diagram_map

Base.:(==)(f::DiagramHom{T}, g::DiagramHom{S}) where {T,S} =
  T == S && shape_map(f) == shape_map(g) && diagram_map(f) == diagram_map(g) &&
  f.precomposed_diagram == g.precomposed_diagram

ob_map(f::DiagramHom, x) = (ob_map(f.shape_map, x), component(f.diagram_map, x))
hom_map(f::DiagramHom, g) = hom_map(f.shape_map, g)

# Categories of diagrams
########################

dom_diagram(f::DiagramHom{id}) = dom(diagram_map(f))
dom_diagram(f::DiagramHom{op}) = f.precomposed_diagram
dom_diagram(f::DiagramHom{co}) = codom(diagram_map(f))
codom_diagram(f::DiagramHom{id}) = f.precomposed_diagram
codom_diagram(f::DiagramHom{op}) = codom(diagram_map(f))
codom_diagram(f::DiagramHom{co}) = f.precomposed_diagram

dom(f::DiagramHom{T}) where T = Diagram{T}(dom_diagram(f))
codom(f::DiagramHom{T}) where T = Diagram{T}(codom_diagram(f))

function id(d::Diagram{T}) where T
  F = diagram(d)
  DiagramHom{T}(id(dom(F)), id(F), F)
end

function compose(f::DiagramHom{id}, g::DiagramHom{id})
  DiagramHom{id}(
    shape_map(f) ⋅ shape_map(g),
    diagram_map(f) ⋅ (shape_map(f) * diagram_map(g)),
    codom_diagram(g))
end
function compose(f::DiagramHom{op}, g::DiagramHom{op})
  DiagramHom{op}(
    shape_map(g) ⋅ shape_map(f),
    (shape_map(g) * diagram_map(f)) ⋅ diagram_map(g),
    dom_diagram(f))
end
function compose(f::DiagramHom{co}, g::DiagramHom{co})
  DiagramHom{co}(
    shape_map(f) ⋅ shape_map(g),
    (shape_map(f) * diagram_map(g)) ⋅ diagram_map(f),
    codom_diagram(g))
end

# TODO: There are actually 2-categories of diagrams, but for now we just
# implement the category struture.

@instance Category{Diagram,DiagramHom} begin
  @import dom, codom, compose, id
end

op(d::Diagram{op}) = Diagram{co}(d)
op(d::Diagram{co}) = Diagram{op}(d)
op(f::DiagramHom{op}) = DiagramHom{co}(f)
op(f::DiagramHom{co}) = DiagramHom{op}(f)

end
