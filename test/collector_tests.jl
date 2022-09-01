
@testset "Adding/Removing" begin
    
end

@testset "Collect on collectors" begin
    

end

@testset "Collector Tests" begin
    @test count("\n", PromClient.generate_latest_collector_metrics()) == 16
    @test count("test:Counter{", PromClient.generate_latest_collector_metrics()) == 4
    @test length(PromClient.DEFAULT_COLLECTOR.metrics) == count("TYPE", PromClient.generate_latest_collector_metrics())  # 4
end