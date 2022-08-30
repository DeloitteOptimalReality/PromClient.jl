module PromClient

using Dates

include("types.jl")
include("metrics.jl")
include("exposition.jl")
include("collectors.jl")
include("utilities.jl")

export CounterMetric, GaugeMetric, HistogramMetric
export inc, dec, set, reset_metric!, observe
export get_bucket_linear, get_bucket_exponential
export generate_latest_collector_metrics, collect
export add_metric_to_collector!, DEFAULT_COLLECTOR

end # module
