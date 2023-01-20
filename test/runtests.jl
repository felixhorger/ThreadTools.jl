
using Revise
using ThreadTools

idx = CartesianIndex.(mod1.(rand(Int, 20), 1000))
sort!(idx)
splits, block_lengths = safe_split_threads(idx, 4)
length.(splits)


