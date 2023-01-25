
module ThreadTools
	
	export safe_split_threads, @letblock, @threads

	"""
		@letblock a b c expr

		gives

		let a=a, b=b, c=c
			\$expr
		end
	"""
	macro letblock(args...)
		vars = @views args[1:end-1]
		expr = args[end]
		return esc(quote
			let $((Expr(:(=), v, v) for v in vars)...)
				$expr
			end
		end)
	end

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


	"""
		Only works for indexable iterators
		prep_vars is a tuple of symbols
		prep_vars = prep_func()
	"""
	macro threads(prep_vars, prep_func, loop)
		# TODO: check if loop is loop
		iter_var, iter = loop.args[1].args
		body = loop.args[2]
		return quote
			let niter, nthreads, per_thread
				niter = length($(esc(iter)))
				nthreads = min(Threads.nthreads(), niter)
				per_thread = niter ÷ nthreads
				$(macroexpand(Main, quote
				@sync for tid = 1:nthreads
					Threads.@spawn let per_thread=per_thread, start
						start = per_thread * (tid - 1)
						rem = mod(niter, nthreads)
						if tid ≤ rem
							per_thread += 1
							start += tid-1
						else
							start += rem
						end
						let $(esc.(prep_vars.args)...)
							$(esc(prep_vars)) = $(esc(prep_func))()
							for i = start+1 : start+per_thread
								local $(esc(iter_var)) = @inbounds $iter[i]
								$(esc(body))
							end
						end
					end
				end
				end))
			end
		end
	end

end

