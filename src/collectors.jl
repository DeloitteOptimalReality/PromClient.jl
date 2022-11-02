
const DEFAULT_COLLECTOR = PromCollector("DEFAULT")

"""Adds the given metric to a given collector. uses the DEFAULT_COLLECTOR if non given."""
function add_metric_to_collector!(p::PromMetric, collector=DEFAULT_COLLECTOR)
    if haskey(collector.metrics, p.name)
        @warn("Duplicate prom metrics with name $(p.name) already exists in collector $(collector.name), has been overwritten! Logging may be incorrect!")
    end
    collector.metrics[p.name] = p
end
