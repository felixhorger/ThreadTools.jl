
module ThreadTools
	
	export safe_split_threads
	
	"""
		idx must be sorted
	"""
	function safe_split_threads(idx::AbstractVector{CartesianIndex{N}}, nthreads::Integer) where N
		# Find block safe to process only sequentially
		k = idx[1]
		blocks = Vector{Int}(undef, 0)
		sizehint!(blocks, length(idx))
		n = 1
		for (i, j) in enumerate(idx)
			k == j && continue
			push!(blocks, n)
			k = j
			n = i
		end
		push!(blocks, length(idx)+1)
		block_lengths = diff(blocks)
		# Find a split which is kind of even
		split_idx = ntuple(_ -> Vector{CartesianIndex{N}}(undef, 0), nthreads)
		sizehint!.(split_idx, length(idx) ÷ nthreads + 1)
		for p in sortperm(block_lengths; rev=true)
			t = argmin(length.(split_idx))
			@views append!(split_idx[t], idx[blocks[p]:blocks[p+1]-1])
		end
		return split_idx, block_lengths
	end

end

