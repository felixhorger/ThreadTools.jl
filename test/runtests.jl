
using Revise
using ThreadTools

idx = mod1.(rand(Int, 3, 1000000), 5)
idx = [CartesianIndex(idx[:, i]...) for i in axes(idx, 2)]

@time splits = safe_split_threads(idx, (1, 3), 4);


i = splits[1][1]
for t = 2:4
	for j in splits[t]
		@assert j[1] != i[1] || j[3] != i[3]
	end
end

length.(splits)


