"""
    _update_timestamp(pm::Prometric, label_key_val::Dict{Set{Pair{String, String}},VT})

Updates the timestamp for a key value pair if pm.log_timestamp is true.
"""
function _update_timestamp(pm::PromMetric, label_key_val::Set{Pair{String, String}})
    if pm.log_timestamp
        pm.label_timestamp[label_key_val] = datetime2epoch(Dates.now())
    end
end


""" 
    _get_label_key_val(pm::PromMetric, label_vals::Vector{String})
    _get_label_key_val(pm::PromMetric)

Helper to get the keys needed in the label_data dict 
only allow no labels vals, if no label keys exist.
"""
function _get_label_key_val(pm::PromMetric, label_vals::Vector{String})
    if length(label_vals) != length(pm.label_keys)
        throw(ErrorException("Number of Label Vals: $(length(label_vals)) does not match number"*
                             " of keys defined in Metric: $(pm.name): $(length(pm.label_keys))"))
    end
    return Set([pm.label_keys[i]=>label for (i,label) in enumerate(label_vals)])
end
function _get_label_key_val(pm::PromMetric)
    if isempty(pm.label_keys)  
        return  _get_label_key_val(pm, String[])
    end
    throw(ErrorException("Updating metric $(pm.name) must include labels, if labels are defined!"))
end

""" 
    inc(pm::PromMetric, label_vals::Vector{String}, val::Number=1)
    inc(pm::PromMetric, val::Number=1)

Increments the label for the metric by given amount. 
If no label is provided, will add to blank label (empty set as key), but this is discouraged.

# Arguments
    - `pm::PromMetric`: reference to the Metric itself
    - `label_vals::Vector{String}`: Vector of the label values, must be in order and 
    matching the length of the label_keys of the metric
    - `val::Number=1`: Value to increment by, defaults to 1. Use correct data type
    
"""
function inc(pm::PromMetric, label_vals::Vector{String}, val::Number=1)
    # Does no validation of the sign of the number, up to user to make sure you don't pass in a negative
    _lkv = _get_label_key_val(pm, label_vals)
    try
        lock(pm._lk)
        pm.label_data[_lkv] = get(pm.label_data, _lkv, 0) + val
		_update_timestamp(pm, _lkv)
    finally
        unlock(pm._lk)
    end
end
function inc(pm::HistogramMetric, label_vals, val)
    throw(ErrorException("Histogram $(pm.name) not allowed to use inc function - use observe() instead!"))
end
function inc(pm::PromMetric, val::Number=1)
    if isempty(pm.label_keys)
        inc(pm, String[], val)  # Disallow call with blank labels, unless no labels defined
    else
        throw(ArgumentError("inc call must supply labels for Metric $(pm.name) as labels keys are defined"))
    end
end

"""Decrements the label for the Gauge metric by given amount."""
function dec(pm::GaugeMetric, label_vals::Vector{String}, val::Number=1)
    inc(pm, label_vals, -1 * val)  # just a negative inc
end
function dec(pm::HistogramMetric, label_vals, val)
    throw(ErrorException("Histogram $(pm.name) not allowed to use dec function - use observe() instead!"))
end
function dec(pm::PromMetric, val::Number=1)
    if isempty(pm.label_keys)
        dec(pm, String[], val)
    else
        throw(ArgumentError("dec call must supply labels for Metric $(pm.name) as labels keys are defined"))
    end
end


"""Sets the label for the metric to some value. Should only be used on Gauges."""
function set(pm::PromMetric, label_vals::Vector{String}, val::Number)
    _lkv = _get_label_key_val(pm, label_vals)
    try
        lock(pm._lk)
        pm.label_data[_lkv] = val
        _update_timestamp(pm, _lkv)
    finally
        unlock(pm._lk)
    end
end
function set(pm::HistogramMetric, label_vals, val)
    throw(ErrorException("Histogram $(pm.name) not allowed to use set function - use observe() instead!"))
end
function set(pm::PromMetric, val::Number=1)
    if isempty(pm.label_keys)
        set(pm, String[], val)  # Disallow call with blank labels, unless no labels defined
    else
        throw(ArgumentError("set call must supply labels for Metric $(pm.name) as labels keys are defined"))
    end
end

"""Sets a gauge to the current unixtime, in seconds."""
function set_to_current_time(pm::GaugeMetric, label_vals::Vector{String})
    set(pm, label_vals, floor(Int, time()))
end


""" Resets label value for the metric to 0."""
function reset_metric!(pm::PromMetric, label_vals::Vector{String})
    set(pm, label_vals, zero(pm._vtype))
end
function reset_metric!(pm::PromMetric)
    for (k,v) in pm.label_data
        pm.label_data[k] = zero(pm._vtype)
    end
end
function reset_metric!(pm::HistogramMetric)
    for (k,v) in pm.label_counts
        v = zeros(length(pm.buckets))
        pm.label_counts[k] = zero(pm._vtype)
    end
end

""" 
    observe(pm::HistogramMetric, label_vals::Vector{String}, val::Number)
    observe(pm::HistogramMetric, val::Number)

Observe a value for histograms & Summaries, places it into the relevant bucket/quantile.
Observation without label is only allowed if the metric itself was created without labels.
    
# TODO
- Implement observe for Summary Metrics.
"""
function observe(pm::HistogramMetric, label_vals::Vector{String}, val::Number)
    _lkb = _get_label_key_val(pm, label_vals)
    bucket_increments = [val <= b for b in pm.buckets]
    try
        lock(pm._lk)
        # create bucket values of zeros if not exist
        pm.label_counts[_lkb] = get(pm.label_counts, _lkb, zeros(length(pm.buckets))
                                    ) .+ bucket_increments
        pm.label_sum[_lkb] = get(pm.label_sum, _lkb, 0) + val
        _update_timestamp(pm, _lkb)
    finally
        unlock(pm._lk)
    end
end
function observe(pm::HistogramMetric, val::Number)
    if !isempty(pm.label_keys)
        throw(ArgumentError("Missing Labels in observe call for Histogram $(pm.name)"))
    end
    observe(pm, String[], val)
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
