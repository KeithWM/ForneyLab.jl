module ClampTest

using Base.Test
using ForneyLab
import ForneyLab: outboundType, isApplicable
import ForneyLab: SPClamp

@testset "Clamp" begin
    g = FactorGraph()
    nd = Clamp(Variable(), 1.0)

    @test isa(nd, Clamp)
    @test nd.value == 1.0
end

@testset "constant" begin
    g = FactorGraph()
    var = constant(1.0, id=:my_constant)
    nd = g.nodes[:my_constant]

    @test isa(var, Variable)
    @test isa(nd, Clamp)
    @test nd.value == 1.0
end

@testset "placeholder" begin
    g = FactorGraph()

    # Standard placeholder
    var = Variable()
    placeholder(var, :y)
    nd = g.nodes[:placeholder_y]

    @test isa(nd, Clamp)
    @test g.placeholders[nd] == (:y, 0)

    # Indexed placeholder
    var_i = Variable()
    placeholder(var_i, :y, index=1)
    nd_i = g.nodes[:placeholder_y_1]

    @test isa(nd_i, Clamp)
    @test g.placeholders[nd_i] == (:y, 1)
end


#-------------
# Update rules
#-------------

@testset "SPClamp" begin
    @test SPClamp{Univariate} <: SumProductRule{Clamp{Univariate}}
    @test outboundType(SPClamp{Univariate}) == Message{PointMass, Univariate}
    @test isApplicable(SPClamp{Univariate}, DataType[]) 

    @test SPClamp{Multivariate} <: SumProductRule{Clamp{Multivariate}}
    @test outboundType(SPClamp{Multivariate}) == Message{PointMass, Multivariate}
    @test isApplicable(SPClamp{Multivariate}, DataType[]) 

    @test SPClamp{MatrixVariate} <: SumProductRule{Clamp{MatrixVariate}}
    @test outboundType(SPClamp{MatrixVariate}) == Message{PointMass, MatrixVariate}
    @test isApplicable(SPClamp{MatrixVariate}, DataType[]) 
end

end #module