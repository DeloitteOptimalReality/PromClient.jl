
@testset "Counter Tests" begin
    tp = CounterMetric("test:Counter", "Int Counter test", ["a", "b", "c"]; t=true)
    add_metric_to_collector!(tp)
    
    tp_k1 = PromClient._get_label_key_val(tp, ["t1", "t2", "t3"])
    tp_k1 == Set([  "b" => "t2", "a" => "t1", "c" => "t3"])
    inc(tp, ["t1", "t2", "t3"])
    tp.label_data[tp_k1] == 1
    @test_throws MethodError dec(tp, ["t1", "t2", "t3"])  # not defined for counter
    
    reset_metric!(tp, ["t1", "t2", "t3"])
    @test tp.label_data[tp_k1] == 0
    
    Threads.@threads for i in 1:10000
        inc(tp,  ["t1", "t2", "t3"]);
    end
    @test tp.label_data[tp_k1] == 10000
    
    Threads.@threads for label_val in ["t1", "t2", "t3"]
        reset_metric!(tp, [label_val, label_val, label_val])
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
    tp_float = CounterMetric("Counter:Float", "32f test", ["host", "podname", "tid"]; t=true, vtype=Float32)
    lfkey1 = ["localhost", "t2", string(Threads.threadid())]
    lfloat1 = PromClient._get_label_key_val(tp_float, lfkey1)
    # TODO Fix adding to the collector
    # add_metric_to_collector!(tp_float)

    inc(tp_float, lfkey1)
    @test tp_float.label_data[lfloat1] == 1.0
    inc(tp_float, lfkey1, 5.5)
    @test tp_float.label_data[lfloat1] == 6.5

    lfkey2 =  ["0.0.0.0", "t1", "9001"]
    lf_label2 = PromClient._get_label_key_val(tp_float, lfkey2)
    inc(tp_float,lfkey2)
    @test tp_float.label_data[lf_label2] == 1.0
    @test length(tp_float.label_data) == 2
    reset_metric!(tp_float, lfkey2)
    @test tp_float.label_data[lf_label2] == 0.0
end

@testset "Gauge Tests" begin
    gm = GaugeMetric("gauge:test", "tests for gauge"; vtype=Float64)
    # TODO Fix adding to the collector
    # add_metric_to_collector!(gm)
    inc(gm)
    @test gm.label_data[Set()] == 1.0
    dec(gm)
    dec(gm, 5.0)
    @test gm.label_data[Set()] == -5.0
    set(gm, 1.5)
    @test gm.label_data[Set()] == 1.5
    reset_metric!(gm)
    @test gm.label_data[Set()] == 0.0
    # print(PromClient.collect(gm))
end

@testset "Histogram Metrics" begin
    
    # buckets must be in order, and end with Inf
    @test_throws ArgumentError failhist = HistogramMetric("testhist"; buckets=(0.4,0.1))
    @test_throws ArgumentError failhist = HistogramMetric("testhist"; buckets=(0.1,0.4))

    hist = HistogramMetric("testhist")
    @test hist.buckets[end] == Inf

    _lkv0 = PromClient._get_label_key_val(hist, String[])
    observe(hist, 0.01)
    observe(hist, 0.4)
    observe(hist, 3)
    observe(hist, 999)

    expected_counts = [3 <= b for b in hist.buckets] .+ [0.01 <= b for b in hist.buckets] .+ [0.4 <= b for b in hist.buckets] .+ [999 <= b for b in hist.buckets]

    for (i, _v) in enumerate(hist.label_counts[_lkv0])
        @test _v == expected_counts[i]
    end
    @test hist.label_sum[_lkv0] == 0.01 + 0.4 + 3 + 999

    observe(hist, Inf)  # if this happens, average and other related calcs will break
    @test hist.label_sum[_lkv0] == Inf
    @test_throws ErrorException inc(hist, [], 1)
    @test_throws ErrorException set(hist, [], 1)
    @test_throws ErrorException dec(hist, [], 1)

    hist_labels = HistogramMetric("h_labs", "test histogram with labels", ["lab1", "lab2"]; buckets=(0.1,1.0,10.0,Inf))
    test_observations = [0.05, 0.5, 5, 11]
    for _o in test_observations
        observe(hist_labels, ["a","b"], _o)
    end

    _hlkv = PromClient._get_label_key_val(hist_labels, ["a","b"])
    @test_throws ErrorException PromClient._get_label_key_val(hist_labels, ["a"])  # number of labels enforced now
    # hist_labels.label_keys
    @test hist_labels.label_counts[_hlkv] == [1.0, 2.0, 3.0, 4.0]
    @test hist_labels.label_sum[_hlkv] == sum(test_observations)

    test_labs2 = ["a", "c"]
    test_obsr2 = [0.11, 0.75, 1, 5.5]
    for _o in test_obsr2
        observe(hist_labels, test_labs2, _o)
    end
    hist_labels.buckets
    _hlkv2 = PromClient._get_label_key_val(hist_labels, test_labs2)
    @test hist_labels.label_counts[_hlkv2] == [0, 3.0, 4.0, 4.0]
    @test hist_labels.label_sum[_hlkv2] == sum(test_obsr2)

    # bucket maker test
    @test (1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, Inf) == get_bucket_linear(1,0.5,4)

    # (1.0, 2.1435469250725863, 3.348369522101714, 4.59479341998814, Inf) == get_bucket_exponential(1,1.1,4)
    @test all((1.0, 2.1435469250725863, 3.348369522101714, 4.59479341998814, Inf) .≈ get_bucket_exponential(1,1.1,4))
end
