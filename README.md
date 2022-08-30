# PromClient.jl
Lightweight Julia Implementation of a Prometheus Client for Julia services. 

At the moment it supports:
- Gauge
- Counter
- Histogram
## Not yet supported Metric types:
- Summary 

## To Do's in future (not yet supported)
- Default System Metrics (CPU time, GC time, memory use etc.).
- Decorators for code timers directly into metrics.

For further on metric types see https://prometheus.io/docs/concepts/metric_types/

# Quick Start
See Tests for more detailed examples.

```
# Create a new metric. Defaults to int, use the vtype kwarg for other numeric types
julia> metric1 = CounterMetric("test:Counter", "Helpful Description String", ["hostname", "port", "threadid"])

# Increase/decrease/set/reset values. Counters only go up, gauges can go up or down
# Histograms use `observe` instead
# Note label values must be string
julia> inc(metric1, ["0.0.0.0", "9001", string(Threads.threadid())]);  # adds 1
julia> inc(metric1, ["0.0.0.0", "9002", "-1"], 10);  # adds 10

# Print output, uses the DEFAULT COLLECTOR
generate_latest_prom_metrics()
```

Which looks something like this:
```
# HELP test:Counter Helpful Description String
# TYPE test:Counter counter
test:Counter{port="9001",hostname="0.0.0.0",threadid="1"} 1
test:Counter{port="9002",hostname="0.0.0.0",threadid="-1"} 10 
```

See https://prometheus.io/docs/instrumenting/exposition_formats/#text-based-format for more details on the required output format.

