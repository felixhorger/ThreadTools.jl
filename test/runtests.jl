
using Revise
using ThreadTools

idx = mod1.(rand(Int, 3, 100000), 256)
idx = [CartesianIndex(idx[:, i]...) for i in axes(idx, 2)]

@time splits = safe_split_threads(idx, (1, 2), 20);

@code_warntype safe_split_threads(idx, (1, 2), 20);


i = splits[1][1]
for t = 2:4
	for j in splits[t]
		@assert j[1] != i[1] || j[3] != i[3]
	end
end

length.(splits)


