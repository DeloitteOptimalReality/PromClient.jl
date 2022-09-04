using Test
using PromClient

@testset "Collector Tests" begin include("collector_tests.jl") end
@testset "Metric Tests" begin include("metric_tests.jl") end
