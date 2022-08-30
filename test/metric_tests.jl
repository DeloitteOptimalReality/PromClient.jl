
@testset "Counter Tests" begin
    tp = CounterMetric("test:Counter", "Int Counter test", ["a", "b", "c"])
    add_metric_to_collector!(tp)
    
    tp_k1 = PromClient._get_label_key_val(tp, ["t1", "t2", "t3"])
    tp_k1 == Set([  "b" => "t2", "a" => "t1", "c" => "t3"])
    inc(tp, ["t1", "t2", "t3"])
    tp.label_data[tp_k1] == 1
    @test_throws MethodError dec(tp, ["t1", "t2", "t3"])  # not defined for counter
    
    reset_metric(tp, ["t1", "t2", "t3"])
    @test tp.label_data[tp_k1] == 0
    
    Threads.@threads for i in 1:10000
        inc(tp,  ["t1", "t2", "t3"]);
    end
    @test tp.label_data[tp_k1] == 10000
    
    Threads.@threads for label_val in ["t1", "t2", "t3"]
        reset_metric(tp, [label_val, label_val, label_val])
        for i in 1:10000
            inc(tp,  [label_val, label_val, label_val], i);
        end
    end
    
    tp_kl2 = ["t1", "t1", "t1"]
    @test length(tp.label_data) == 4
    tp_k2 = PromClient._get_label_key_val(tp, tp_kl2)
    @test tp.label_data[tp_k2] == sum(1:10000)
    @test_throws MethodError set(tp, tp_kl2)
    set(tp, tp_kl2, -100)
    @test tp.label_data[tp_k2] == -100
    
end

@testset "Float/Value type Tests" begin
    tp_float = CounterMetric("Counter:Float", "32f test", ["host", "podname", "tid"]; vtype=Float32)
    lfkey1 = ["localhost", "t2", string(Threads.threadid())]
    lfloat1 = PromClient._get_label_key_val(tp_float, lfkey1)
    add_metric_to_collector!(tp_float)

    inc(tp_float, lfkey1)
    @test tp_float.label_data[lfloat1] == 1.0
    inc(tp_float, lfkey1, 5.5)
    @test tp_float.label_data[lfloat1] == 6.5

    lfkey2 =  ["0.0.0.0", "t1", "9001"]
    lf_label2 = PromClient._get_label_key_val(tp_float, lfkey2)
    inc(tp_float,lfkey2)
    @test tp_float.label_data[lf_label2] == 1.0
    @test length(tp_float.label_data) == 2
    reset_metric(tp_float, lfkey2)
    @test tp_float.label_data[lf_label2] == 0.0
end

@testset "Gauge Tests" begin
    gm = GaugeMetric("gauge:test", "tests for gauge"; vtype=Float64)
    add_metric_to_collector!(gm)
    inc(gm)
    @test gm.label_data[Set()] == 1.0
    dec(gm)
    dec(gm, 5.0)
    @test gm.label_data[Set()] == -5.0
    set(gm, 1.5)
    @test gm.label_data[Set()] == 1.5
    reset_metric(gm)
    @test gm.label_data[Set()] == 0.0
    # print(PromClient._prometheus_format(gm))
end


@testset "Formatting Tests" begin
    lab_pai_1 = Set(["host" => "localhost","tid" => "1","podname" => "t2"])
    @test PromClient._prometheus_format_label("testmetric",lab_pai_1, 1.0) == "testmetric{host=\"localhost\",tid=\"1\",podname=\"t2\"} 1.0"
    
    pm_format = GaugeMetric("formatter_test", "format test", ["host"])  # when testing formatting, using multiple labels might be jumbled. To fix later
    add_metric_to_collector!(pm_format)
    inc(pm_format, ["localhost"])
    @test PromClient._prometheus_format(pm_format) == "# HELP formatter_test format test\n# TYPE formatter_test gauge\nformatter_test{host=\"localhost\"} 1 \n\n"
    dec(pm_format, ["localhost2"])
    # example output format
    formatted_string = """# HELP formatter_test format test
    # TYPE formatter_test gauge
    formatter_test{host=\"localhost\"} 1 
    formatter_test{host=\"localhost2\"} -1 
    
    """
    @test PromClient._prometheus_format(pm_format) == formatted_string

    pretty_format = """
    format test (localhost): 1 
    format test (localhost2): -1 

    """
    @test PromClient._prometheus_pretty(pm_format) == pretty_format
    @test PromClient.generate_pretty_prom_metrics([pm_format]) == pretty_format

    # number of lines
    @test count("\n", PromClient._prometheus_format(pm_format)) == 5
end

# print(generate_latest())  # uncomment to check format


@testset "Collector Tests" begin
    count("\n", generate_latest_prom_metrics()) == 21
    count("testCounter{", generate_latest_prom_metrics()) == 4
    length(PromClient.DEFAULT_COLLECTOR) == count("TYPE", generate_latest_prom_metrics())  # 4
end

