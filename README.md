# PromClient.jl
Lightweight Julia Implementation of a Prometheus Client for Julia services. 

At the moment it supports:
- Gauge
- Counter
- Histogram
## Not yet supported Metric types:
- Summary 

# Done List (Remove before publishing)
- Histograms:
    - Setup struct with hist fields
    - Functions to Configure buckets, incl. default bucket
    - disallow prom metric from being called on histograms.
- Enforce correct number of labels in all setter functions

# TODOs before we publish initial version
- Exposition Functions to 'collect' data from Histograms
- Fix Default prom collector
    - Change to Collector Struct/class.
    - Constructor of prom metrics to add to default registry.

# Sach to do
- optional timestamps after metrics
- fix remaining test

# interface changes from PrometheusClient (Internal reference only - do not publish)
- change in function name: `reset_metric` => `reset_metric!`
- change in function name: `_prometheus_format` => `collect`, for a single metric. This was not previous exported anyway
- `PromCollector` is now a Struct, instead of vector of Metrics

## To Do's in future (not yet supported)
- Default System Metrics (CPU time, GC time, memory use etc.)
- Decorators for code timers directly into metrics

For further on metric types see https://prometheus.io/docs/concepts/metric_types/

# Quickstart
See Tests for more detailed examples

```
# create a new metric. Defaults to int, use the vtype kwarg for other numeric types
julia> metric1 = CounterMetric("test:Counter", "Helpful Description String", ["hostname", "port", "threadid"])

julia> add_metric_to_collector!(metric1)  # adds to default collector, used to generate the metric output

# increase/decrease/set/reset values. Counters only go up, gauges can go up or down.
# note label values must be string
julia> inc(metric1, ["0.0.0.0", "9001", string(Threads.threadid())]);  # adds 1
julia> inc(metric1, ["0.0.0.0", "9002", "-1"], 10);  # adds 10

# print output, uses the DEFAULT COLLECTOR
generate_latest_prom_metrics()
```

Which looks something like
```
# HELP test:Counter Helpful Description String
# TYPE test:Counter counter
test:Counter{port="9001",hostname="0.0.0.0",threadid="1"} 1
test:Counter{port="9002",hostname="0.0.0.0",threadid="-1"} 10 
```

See https://prometheus.io/docs/instrumenting/exposition_formats/#text-based-format for more details on the required output format

## Known issues
Note the default collector isn't properly working with JuliaAppTemplate Apps yet - for the moment please define your own collector
 which is just a vector of PromMetric objects, i.e. like `PromMetric[]`

## Template Version Used

This application generated with or-sdk JuliaAppTemplate v0.2.37