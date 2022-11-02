
@testset "Prom Label Formatting" begin
    lab_pai_1 = Set(["host" => "localhost","tid" => "1","podname" => "t2"])
    @test PromClient._prometheus_format_label("testmetric",lab_pai_1, 1.0) == "testmetric{host=\"localhost\",tid=\"1\",podname=\"t2\"} 1.0"
    
    
    lab_hist_test = "test_histo_bucket{lab1=\"a\",lab2=\"fixed\",le=\"0.5\"} 2.0"
    @test PromClient._prometheus_format_label("test_histo_bucket", Set(["host"=>"localhost","podname" => "t2"]), 2.0; bucket=0.5) == "test_histo_bucket{host=\"localhost\",podname=\"t2\",le=\"0.5\"} 2.0"
    
end

@testset "Counter Format" begin
    test_metrics = CounterMetric("test:counter:metric", "Metric Format test", ["host", "tid", "podname"]; t=true)
    add_metric_to_collector!(test_metrics)
    test_metric_data = ["localhost","1","t2"]
    set(test_metrics, test_metric_data, 1.0)
    _kv = PromClient._get_label_key_val(test_metrics, test_metric_data)
    @test PromClient._prometheus_format_label(test_metrics, _kv, 1.0) == "test:counter:metric{host=\"localhost\",tid=\"1\",podname=\"t2\"} 1.0 $(test_metrics.label_timestamp[_kv])"

    test_metrics_1 = CounterMetric("test:Counter:metric1", "Metric Format test", ["host", "tid", "podname"])
    add_metric_to_collector!(test_metrics_1)
    test_metric_data_1 = ["localhost","1","t2"]
    set(test_metrics_1, test_metric_data_1, 1.0)
    _kv_1 = PromClient._get_label_key_val(test_metrics_1, test_metric_data_1)
    @test PromClient._prometheus_format_label(test_metrics_1, _kv_1, 1.0) == "test:Counter:metric1{host=\"localhost\",tid=\"1\",podname=\"t2\"} 1.0"
end

@testset "Gauge Format" begin
    pm_format = GaugeMetric("formatter_test", "format test", ["host"])  # when testing formatting, using multiple labels might be jumbled. To fix later
    inc(pm_format, ["localhost"])
    @test PromClient.collect(pm_format) == "# HELP formatter_test format test\n# TYPE formatter_test gauge\nformatter_test{host=\"localhost\"} 1 \n\n"
    dec(pm_format, ["localhost2"])
    # example output format
    formatted_string = """# HELP formatter_test format test
    # TYPE formatter_test gauge
    formatter_test{host=\"localhost\"} 1 
    formatter_test{host=\"localhost2\"} -1 
    
    """
    @test PromClient.collect(pm_format) == formatted_string

    @test count("\n", PromClient.collect(pm_format)) == 5
    
    pm_format_1 = GaugeMetric("formatter_test_1", "format test", ["host"]; t=true)  # when testing formatting, using multiple labels might be jumbled. To fix later
    add_metric_to_collector!(pm_format_1)
    inc(pm_format_1, ["localhost"])
    _kv_pm = PromClient._get_label_key_val(pm_format_1, ["localhost"])
    @test PromClient.collect(pm_format_1) == "# HELP formatter_test_1 format test\n# TYPE formatter_test_1 gauge\nformatter_test_1{host=\"localhost\"} 1 $(pm_format_1.label_timestamp[_kv_pm]) \n\n"
    dec(pm_format_1, ["localhost2"])
    _kv_pm_1 = PromClient._get_label_key_val(pm_format_1, ["localhost2"])
    # example output format
    formatted_string = """# HELP formatter_test_1 format test
    # TYPE formatter_test_1 gauge
    formatter_test_1{host=\"localhost\"} 1 $(pm_format_1.label_timestamp[_kv_pm]) 
    formatter_test_1{host=\"localhost2\"} -1 $(pm_format_1.label_timestamp[_kv_pm_1]) 
    
    """
    @test PromClient.collect(pm_format_1) == formatted_string

    @test count("\n", PromClient.collect(pm_format_1)) == 5
end

@testset "Histogram Format" begin
    hist_format = HistogramMetric("hist_test", "format test", ["host"]; buckets=(0.4, Inf))  
    # TODO Add the default collector test
    # add_metric_to_collector!(hist_format)
    
    observe(hist_format, ["localhost"], 1.0)
    test_hist_expo = """# HELP hist_test format test
    # TYPE hist_test histogram
    hist_test_bucket{host=\"localhost\",le=\"0.4\"} 0.0
    hist_test_bucket{host=\"localhost\",le=\"Inf\"} 1.0
    hist_test_count{host=\"localhost\"} 1.0
    hist_test_sum{host=\"localhost\"} 1.0 \n
    """

    @test count("\n", PromClient.collect(hist_format)) == 7  # note new line at end
    
    PromClient.collect(hist_format) == test_hist_expo
    observe(hist_format, ["localhost2"], 0.1)
    test_hist_expo_2 = """# HELP hist_test format test
    # TYPE hist_test histogram
    hist_test_bucket{host=\"localhost\",le=\"0.4\"} 0.0
    hist_test_bucket{host=\"localhost\",le=\"Inf\"} 1.0
    hist_test_count{host=\"localhost\"} 1.0
    hist_test_sum{host=\"localhost\"} 1.0
    hist_test_bucket{host=\"localhost2\",le=\"0.4\"} 1.0
    hist_test_bucket{host=\"localhost2\",le=\"Inf\"} 1.0
    hist_test_count{host=\"localhost2\"} 1.0
    hist_test_sum{host=\"localhost2\"} 0.1 \n
    """
    ## this Test won't be stable due to sets not being ordered, just here to show the 
    ## expected format in one of the potential orders. In either case it will be 
    ## Compatible with the prom spec/prom scrapers in actual use.
    # @test PromClient.collect(hist_format) == test_hist_expo_2
    
    @test count("\n", PromClient.collect(hist_format)) == 11  # 10 lines expected, per above
    
    # Larger histogram test with default buckets
    hist_labels = HistogramMetric("test_histo", "test histogram with labels", ["lab1", "lab2"])
    test_observations = [0.1, 0.5, 0.9, 3.5, 9.0]
    test_observations_b = [0.01, 0.02, 0.05, 1.0, 2.0]
    for _o in test_observations
        observe(hist_labels, ["a","fixed"], _o)
    end
    for _o in test_observations_b
        observe(hist_labels, ["b","fixed"], _o)
    end

    t1 = PromClient._prometheus_format_label(hist_labels, Set(["lab1"=>"a","lab2" => "fixed"]), 2.0, 0.5)
    t2 = PromClient._prometheus_format_label("test_histo_bucket", Set(["lab1"=>"a","lab2" => "fixed"]), 2.0; bucket=0.5)
    @test t1 == t2  # check the metric level formatter matches the string formatter
    
    ## NOTE
    ## Because The actual order of results  may have different labels come first,
    ## have both possible options tested. If 1 is true then we are OK
    test_hist_expo_allbuckets_option1 = """# HELP test_histo test histogram with labels
# TYPE test_histo histogram
test_histo_bucket{lab1="b",lab2="fixed",le="0.005"} 0.0
test_histo_bucket{lab1="b",lab2="fixed",le="0.01"} 1.0
test_histo_bucket{lab1="b",lab2="fixed",le="0.025"} 2.0
test_histo_bucket{lab1="b",lab2="fixed",le="0.05"} 3.0
test_histo_bucket{lab1="b",lab2="fixed",le="0.075"} 3.0
test_histo_bucket{lab1="b",lab2="fixed",le="0.1"} 3.0
test_histo_bucket{lab1="b",lab2="fixed",le="0.25"} 3.0
test_histo_bucket{lab1="b",lab2="fixed",le="0.5"} 3.0
test_histo_bucket{lab1="b",lab2="fixed",le="0.75"} 3.0
test_histo_bucket{lab1="b",lab2="fixed",le="1.0"} 4.0
test_histo_bucket{lab1="b",lab2="fixed",le="2.5"} 5.0
test_histo_bucket{lab1="b",lab2="fixed",le="5.0"} 5.0
test_histo_bucket{lab1="b",lab2="fixed",le="7.5"} 5.0
test_histo_bucket{lab1="b",lab2="fixed",le="10.0"} 5.0
test_histo_bucket{lab1="b",lab2="fixed",le="Inf"} 5.0
test_histo_count{lab1="b",lab2="fixed"} 5.0
test_histo_sum{lab1="b",lab2="fixed"} 3.08
test_histo_bucket{lab1="a",lab2="fixed",le="0.005"} 0.0
test_histo_bucket{lab1="a",lab2="fixed",le="0.01"} 0.0
test_histo_bucket{lab1="a",lab2="fixed",le="0.025"} 0.0
test_histo_bucket{lab1="a",lab2="fixed",le="0.05"} 0.0
test_histo_bucket{lab1="a",lab2="fixed",le="0.075"} 0.0
test_histo_bucket{lab1="a",lab2="fixed",le="0.1"} 1.0
test_histo_bucket{lab1="a",lab2="fixed",le="0.25"} 1.0
test_histo_bucket{lab1="a",lab2="fixed",le="0.5"} 2.0
test_histo_bucket{lab1="a",lab2="fixed",le="0.75"} 2.0
test_histo_bucket{lab1="a",lab2="fixed",le="1.0"} 3.0
test_histo_bucket{lab1="a",lab2="fixed",le="2.5"} 3.0
test_histo_bucket{lab1="a",lab2="fixed",le="5.0"} 4.0
test_histo_bucket{lab1="a",lab2="fixed",le="7.5"} 4.0
test_histo_bucket{lab1="a",lab2="fixed",le="10.0"} 5.0
test_histo_bucket{lab1="a",lab2="fixed",le="Inf"} 5.0
test_histo_count{lab1="a",lab2="fixed"} 5.0
test_histo_sum{lab1="a",lab2="fixed"} 14.0\n
"""
    test_hist_expo_allbuckets_option2 = """# HELP test_histo test histogram with labels
# TYPE test_histo histogram
test_histo_bucket{lab1="a",lab2="fixed",le="0.005"} 0.0
test_histo_bucket{lab1="a",lab2="fixed",le="0.01"} 0.0
test_histo_bucket{lab1="a",lab2="fixed",le="0.025"} 0.0
test_histo_bucket{lab1="a",lab2="fixed",le="0.05"} 0.0
test_histo_bucket{lab1="a",lab2="fixed",le="0.075"} 0.0
test_histo_bucket{lab1="a",lab2="fixed",le="0.1"} 1.0
test_histo_bucket{lab1="a",lab2="fixed",le="0.25"} 1.0
test_histo_bucket{lab1="a",lab2="fixed",le="0.5"} 2.0
test_histo_bucket{lab1="a",lab2="fixed",le="0.75"} 2.0
test_histo_bucket{lab1="a",lab2="fixed",le="1.0"} 3.0
test_histo_bucket{lab1="a",lab2="fixed",le="2.5"} 3.0
test_histo_bucket{lab1="a",lab2="fixed",le="5.0"} 4.0
test_histo_bucket{lab1="a",lab2="fixed",le="7.5"} 4.0
test_histo_bucket{lab1="a",lab2="fixed",le="10.0"} 5.0
test_histo_bucket{lab1="a",lab2="fixed",le="Inf"} 5.0
test_histo_count{lab1="a",lab2="fixed"} 5.0
test_histo_sum{lab1="a",lab2="fixed"} 14.0
test_histo_bucket{lab1="b",lab2="fixed",le="0.005"} 0.0
test_histo_bucket{lab1="b",lab2="fixed",le="0.01"} 1.0
test_histo_bucket{lab1="b",lab2="fixed",le="0.025"} 2.0
test_histo_bucket{lab1="b",lab2="fixed",le="0.05"} 3.0
test_histo_bucket{lab1="b",lab2="fixed",le="0.075"} 3.0
test_histo_bucket{lab1="b",lab2="fixed",le="0.1"} 3.0
test_histo_bucket{lab1="b",lab2="fixed",le="0.25"} 3.0
test_histo_bucket{lab1="b",lab2="fixed",le="0.5"} 3.0
test_histo_bucket{lab1="b",lab2="fixed",le="0.75"} 3.0
test_histo_bucket{lab1="b",lab2="fixed",le="1.0"} 4.0
test_histo_bucket{lab1="b",lab2="fixed",le="2.5"} 5.0
test_histo_bucket{lab1="b",lab2="fixed",le="5.0"} 5.0
test_histo_bucket{lab1="b",lab2="fixed",le="7.5"} 5.0
test_histo_bucket{lab1="b",lab2="fixed",le="10.0"} 5.0
test_histo_bucket{lab1="b",lab2="fixed",le="Inf"} 5.0
test_histo_count{lab1="b",lab2="fixed"} 5.0
test_histo_sum{lab1="b",lab2="fixed"} 3.08\n
"""
    @test PromClient.collect(hist_labels) == test_hist_expo_allbuckets_option2 || PromClient.collect(hist_labels) == test_hist_expo_allbuckets_option1
end

# print(generate_latest_collector_metrics())  # run this to check format