
@testset "Adding/Removing" begin
    
end

@testset "Collect on collectors" begin
    

end

@testset "Collector Tests" begin
    count("\n", generate_latest_prom_metrics()) == 21
    count("testCounter{", generate_latest_prom_metrics()) == 4
    length(PromClient.DEFAULT_COLLECTOR) == count("TYPE", generate_latest_prom_metrics())  # 4
end