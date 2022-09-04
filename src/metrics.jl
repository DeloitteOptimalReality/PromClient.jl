
""" 
    _get_label_key_val(pm::PromMetric, label_vals::Vector{String})

Helper to get the keys needed in the label_data dict 

# Notes

"""
function _get_label_key_val(pm::PromMetric, label_vals::Vector{String})
    # TODO check if labels even exist - return a blank label if not exist
    if isempty(pm.label_data)
    return String[]
    else
    # also, for histo/summary, must insert the 'le' or 'quantile' - though this might be exposition only
    # Disallow Non matched value keys, check for same length
    return Set([pm.label_keys[i]=>label for (i,label) in enumerate(label_vals)])
    end
end

""" 
    inc(pm::PromMetric, label_vals::Vector{String}, val::Number=1)
    inc(pm::PromMetric, val::Number=1)

Increments the label for the metric by given amount. 
If no label is provided, will add to blank label (empty set as key), but this is discouraged

# Arguments
    - `pm::PromMetric`: reference to the Metric itself
    - `label_vals::Vector{String}`: Vector of the label values, must be in order and 
    matching the length of the label_keys of the metric
    - `val::Number=1`: Value to increment by, defaults to 1. Use correct data type
    
"""
function inc(pm::PromMetric, label_vals::Vector{String}, val::Number=1)
    # does no validation of the sign of the number, up to user to make sure you don't pass in a negative
    _label_key_val = _get_label_key_val(pm, label_vals)
    try
        lock(pm._lk)
        if haskey(pm.label_data, _label_key_val)
            pm.label_data[_label_key_val] += val
        else
            pm.label_data[_label_key_val] = val
        end
    finally
        unlock(pm._lk)
    end
end
function inc(pm::HistogramMetric, label_vals, val)
    throw(ErrorException("Histogram $(pm.name) not allowed to use inc function - use observe() instead!"))
end
# TODO Disallow blank labels! Must match number of inputs
# function inc(pm::PromMetric, val::Number=1)
#     inc(pm, String[], val)  
# end

""" Decrements the label for the Gauge metric by given amount. See set() for help"""
function dec(pm::GaugeMetric, label_vals::Vector{String}, val::Number=1)
    inc(pm, label_vals, -1 * val)  # just a negative inc
end
function dec(pm::HistogramMetric, label_vals, val)
    throw(ErrorException("Histogram $(pm.name) not allowed to use dec function - use observe() instead!"))
end

# TODO Disallow blank labels! Must match number of inputs
# function dec(pm::PromMetric, val::Number=1)
#     dec(pm, String[], val)
# end


""" Sets the label for the metric to some value. Should only be used on Gauges."""
function set(pm::PromMetric, label_vals::Vector{String}, val::Number)
    _label_key_val = _get_label_key_val(pm, label_vals)
    try
        lock(pm._lk)
        pm.label_data[_label_key_val] = val
    finally
        unlock(pm._lk)
    end
end

""" Sets a gauge to the current unixtime, in seconds """
function set_to_current_time(pm::GaugeMetric, label_vals::Vector{String})
    set(pm, label_vals, floor(Int, time()))
end
# TODO handle blank labels
# function set(pm::PromMetric, val::Number=1)
#     set(pm, String[], val)  # blank labels, this is discouraged
# end

function set(pm::HistogramMetric, label_vals, val)
    throw(ErrorException("Histogram $(pm.name) not allowed to use set function - use observe() instead!"))
end

""" Resets label value for the metric to 0."""
function reset_metric(pm::PromMetric, label_vals::Vector{String})
    set(pm, label_vals, 0)
end
function reset_metric(pm::PromMetric)
    reset_metric(pm, String[])  # blank labels, this is discouraged
end
function reset_metric(pm::HistogramMetric)
    # TODO implement this
end

""" 
    observe(pm::HistogramMetric, label_vals::Vector{String}, val::Number)

Observe a value for histograms & Summaries, places it into the relevant bucket/quantile

# TODO
- Summary Metrics
"""
function observe(pm::HistogramMetric, label_vals::Vector{String}, val::Number)
    _label_key_val = _get_label_key_val(pm, label_vals)
    try
        lock(pm._lk)
        # TODO go through and check which ones to add
        # pm.label_data[_label_key_val] = val
        
    finally
        unlock(pm._lk)
    end
end

"""
    Methods to Create histogram buckets

# Note
You can create your own buckets, just needs to follow these rules:
- Be an NTuple of Float64 (an Alias of Tuple{Vararg{Float64}})
- Be in Ascending order
- Last value in NTuple must be Inf
"""
function get_bucket_linear(start, width, stop)::Tuple{Vararg{Float64}}
    return Tuple(vcat([i for i in start:width:stop], [Inf]))
end
function get_bucket_exponential(start, factor, count)::Tuple{Vararg{Float64}}
    return Tuple(vcat([i^factor for i in start:count], [Inf]))
end