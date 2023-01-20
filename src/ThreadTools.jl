
module ThreadTools
	
	export safe_split_threads

	"""
		no need to sort idx
	"""
	function safe_split_threads(
		idx::AbstractVector{CartesianIndex{N}},
		protect::NTuple{M, Integer},
		nthreads::Integer
	) where {N, M}
		# Sort by protected indices
		idx = sort(idx; by = i -> CartesianIndex{M}((i[l] for l in protect)...))
		# Find block safe to process only sequentially
		k = idx[1]
		blocks = Vector{Int}(undef, 0)
		sizehint!(blocks, length(idx))
		n = 1
		for (i, j) in enumerate(idx)
			# Continue if protected indices are equal
			# Note: this is practically C-code because the type inference of julia fails if a
			# much nicer generator-one-liner is used ...
			equal = true
			for l in protect
				if k[l] != j[l]
					equal = false
					break
				end
			end
			equal && continue
			# Indices differ, start new block
			push!(blocks, n)
			k = j
			n = i
		end
		push!(blocks, length(idx)+1)
		block_lengths = diff(blocks)
		# Find a split which is kind of even
		split_idx = [Vector{CartesianIndex{N}}(undef, 0) for t = 1:nthreads]
		sizehint!.(split_idx, length(idx) ÷ nthreads + 1)
		lengths = Vector{Int}(undef, nthreads)
		for p in sortperm(block_lengths; rev=true)
			lengths .= length.(split_idx)
			t = argmin(lengths)
			@views append!(split_idx[t], idx[blocks[p]:blocks[p+1]-1])
		end
		return sort.(split_idx)
	end

end

