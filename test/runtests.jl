using Test
using PromClient

@testset "Metric Tests" begin include("metric_tests.jl") end
@testset "Collector Tests" begin include("collector_tests.jl") end


# TODO
@testset "Histogram Exposition" begin
    
    
end