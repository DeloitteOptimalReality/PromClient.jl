module PromClient

include("types.jl")
include("metrics.jl")
include("exposition.jl")
include("collectors.jl")

export CounterMetric, GaugeMetric, PromMetric
export inc, dec, set, reset_metric
export generate_latest_prom_metrics
export add_metric_to_collector!, DEFAULT_COLLECTOR

end # module
