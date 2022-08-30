# TODO - not yet implemented
# Custom collector struct/methods for compliance with Prometheus library
# at the moment, only the default collector is provided (as a dict), This may require re-implementation

const DEFAULT_COLLECTOR = PromMetric[]

""" Adds the given metric to a given collector. uses the DEFAULT_COLLECTOR if non given"""
function add_metric_to_collector!(p::PromMetric, collector=DEFAULT_COLLECTOR)
    for c in collector
        if c.name == p.name
            @error("Duplicate prom metrics with name $(c.name) have been added! Logging may be incorrect!")
        end
    end
    push!(collector, p)
end