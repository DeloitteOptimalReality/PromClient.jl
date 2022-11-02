
@testset "Adding/Removing" begin
    # TODO
end

@testset "Collect on collectors" begin
    # TODO
end

@testset "Collector Tests" begin
    # print(PromClient.generate_latest_collector_metrics())  # uncomment to check exposition output
    @test count("\n", PromClient.generate_latest_collector_metrics()) == 117
    @test count("test:Counter{", PromClient.generate_latest_collector_metrics()) == 4
    @test length(PromClient.DEFAULT_COLLECTOR.metrics) == count("TYPE", PromClient.generate_latest_collector_metrics())  # 4
end