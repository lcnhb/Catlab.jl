module TestRelationalPrograms
using Test

using Catlab.CategoricalAlgebra.CSets
using Catlab.WiringDiagrams.UndirectedWiringDiagrams
using Catlab.Programs.RelationalPrograms

# Relation macro
################

# Untyped
#--------

parsed = @relation (x,z) where (x,y,z) begin
  R(x,y)
  S(y,z)
end

d = RelationDiagram(2)
add_box!(d, 2, name=:R); add_box!(d, 2, name=:S)
add_junctions!(d, 3, variable=[:x,:y,:z])
set_junction!(d, [1,2,2,3])
set_junction!(d, [1,3], outer=true)
@test parsed == d

parsed = @relation ((x,z) where (x,y,z)) -> (R(x,y); S(y,z))
@test parsed == d
parsed = @relation function (x,z) where (x,y,z); R(x,y); S(y,z) end
@test parsed == d

# Abbreviated syntax where context is inferred.
d1 = @relation (x,y,z) -> (R(x,y); S(y,z))
d2 = @relation ((x,y,z) where (x,y,z)) -> (R(x,y); S(y,z))
@test d1 == d2

d1 = @relation (x,z) -> (R(x,y); S(y,z))
d2 = @relation ((x,z) where (x,z,y)) -> (R(x,y); S(y,z))
@test d1 == d2

# Special case: closed diagram.
parsed = @relation (() where (a,)) -> R(a,a)
d = RelationDiagram(0)
add_box!(d, 2, name=:R)
add_junction!(d, variable=:a); set_junction!(d, [1,1])
@test parsed == d

parsed = @relation () -> A()
d = RelationDiagram(0)
add_box!(d, 0, name=:A)
@test parsed == d

# Typed
#------

parsed = @relation (x,y,z) where (x::X, y::Y, z::Z, w::W) begin
  R(x,w)
  S(y,w)
  T(z,w)
end
d = RelationDiagram([:X,:Y,:Z])
add_box!(d, [:X,:W], name=:R)
add_box!(d, [:Y,:W], name=:S)
add_box!(d, [:Z,:W], name=:T)
add_junctions!(d, [:X,:Y,:Z,:W], variable=[:x,:y,:z,:w])
set_junction!(d, [1,4,2,4,3,4])
set_junction!(d, [1,2,3], outer=true)
@test parsed == d

# Untyped, named ports
#---------------------

parsed = @relation (start=u, stop=w) where (u, v, w) begin
  E(src=u, tgt=v)
  E(src=v, tgt=w)
end
d = RelationDiagram(2, port_names=[:start, :stop])
add_box!(d, 2, name=:E)
add_box!(d, 2, name=:E)
add_junctions!(d, 3, variable=[:u,:v,:w])
set_junction!(d, [1,2,2,3])
set_junction!(d, [1,3], outer=true)
set_subpart!(d, :port_name, [:src, :tgt, :src, :tgt])
@test parsed == d

# Abbreviated syntax where context is inferred.
d1 = @relation (start=u, mid=v, stop=w) -> (E(src=u, tgt=v); E(src=v, tgt=w))
d2 = @relation ((start=u, mid=v, stop=w) where (u,v,w)) ->
  (E(src=u, tgt=v); E(src=v, tgt=w))
@test d1 == d2

d1 = @relation (start=u, stop=w) -> (E(src=u, tgt=v); E(src=v, tgt=w))
d2 = @relation ((start=u, stop=w) where (u,w,v)) ->
  (E(src=u, tgt=v); E(src=v, tgt=w))
@test d1 == d2

# Special case: unary named tuple syntax.
parsed = @relation ((src=v) where (v, w)) -> E(src=v, tgt=w)
@test parsed[:outer_port_name] == [:src]

# Special case: closed diagram.
if VERSION >= v"1.5"
  d1 = @relation ((;) where (v,)) -> E(src=v, tgt=v)
  @test subpart(d1, :port_name) == [:src, :tgt]

  d2 = @relation (;) -> E(src=v, tgt=v)
  @test d1 == d2
end

# Typed, named ports
#-------------------

parsed = @relation (e=e, e′=e′) where (e::Employee, e′::Employee,
                                       d::Department) begin
  Employee(id=e, department=d)
  Employee(id=e′, department=d)
end
d = RelationDiagram([:Employee, :Employee], port_names=[:e,:e′])
add_box!(d, [:Employee, :Department], name=:Employee)
add_box!(d, [:Employee, :Department], name=:Employee)
add_junctions!(d, [:Employee, :Employee, :Department], variable=[:e,:e′,:d])
set_junction!(d, [1,3,2,3])
set_junction!(d, [1,2], outer=true)
set_subpart!(d, :port_name, [:id, :department, :id, :department])
@test parsed == d

end
