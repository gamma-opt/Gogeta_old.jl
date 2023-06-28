struct TEModel
    n_trees::Int64
    n_feats::Int64
    n_leaves::Array{Int64}
    leaves::Array{Array}
    splits::Matrix{Any}
    splits_ordered::Array{Vector}
    n_splits::Array{Int64}
    predictions::Array{Array}
    split_nodes::Array{Array}
end