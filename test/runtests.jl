using Test
using PromClient

@testset "Metric Tests" begin include("metric_tests.jl") end
@testset "Exposition Tests" begin include("exposition_tests.jl") end
@testset "Collector Tests" begin include("collector_tests.jl") end
