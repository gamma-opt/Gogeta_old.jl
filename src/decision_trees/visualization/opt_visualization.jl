using Plots
using ColorSchemes

dataset = "OX2";
parent_directory = "/Users/eetureijonen/Desktop/THESIS/ML_as_MO/src/decision_trees/";

filepath = parent_directory*"/test_results/"*dataset*"_opt_results.txt";

filternums(text) = try parse(Float64, text) catch error NaN end;
index = Dict([(3, 1), (5, 2), (7, 3), (9, 4), (12, 5)]);

elements = dataset == "3A4" ? 4 : 5;
depths = dataset == "3A4" ? [3, 5, 7, 9] : [3, 5, 7, 9, 12]

solution_times = Array{Array}(undef, elements);
[solution_times[depth] = [] for depth in 1:elements];

solution_times_alg = Array{Array}(undef, elements);
[solution_times_alg[depth] = [] for depth in 1:elements];

number_of_leaves = Array{Array}(undef, elements);
[number_of_leaves[depth] = [] for depth in 1:elements];

number_of_init_cons = Array{Array}(undef, elements);
[number_of_init_cons[depth] = [] for depth in 1:elements];

number_of_added_cons = Array{Array}(undef, elements);
[number_of_added_cons[depth] = [] for depth in 1:elements];

trees = [50, 100, 200, 350, 500, 750, 1000];

for line in eachline(filepath)
    
    numbers = filter(num->!isnan(num), filternums.(replace.(string.(split(line, " ")), (","=>""))))

    if length(numbers) == 12

        n_trees = Int.(numbers[1])
        depth = Int.(numbers[2])

        pre_time_normal = numbers[3]
        opt_time_normal = numbers[4]

        pre_time_alg = numbers[6]
        opt_time_alg = numbers[7]

        n_levels = Int.(numbers[9])
        n_leaves = Int.(numbers[10])

        init_cons = Int.(numbers[11])
        added_cons = Int.(numbers[12])

        push!(number_of_added_cons[index[depth]], added_cons)
        push!(number_of_init_cons[index[depth]], init_cons)
        push!(solution_times[index[depth]], opt_time_normal)
        push!(solution_times_alg[index[depth]], opt_time_alg)

    end
end

""" NUMBER OF TREES - OPT TIME """

plot(    
    map(len -> trees[1:len], length.([subarray[2:end] for subarray in solution_times])), 
    [subarray[2:end] for subarray in solution_times],
    markershape=:xcross, 
    palette=:rainbow,
    legend=:topright,
    yscale=:log10,
    yticks=([0.1, 1, 10, 100, 1000, 10000], string.([0.1, 1, 10, 100, 1000, 10000])),
    ylabel="Solution time (seconds)",
    xlabel="Number of trees",
    label=["Depth 3" "Depth 5" "Depth 7" "Depth 9" "Depth 12"],
    title="Optimization performance for "*dataset*" dataset"
)

""" NUMBER OF CONSTRAINTS - OPT TIME """

plot(    
    [subarray[2:end] for subarray in number_of_init_cons],
    [subarray[2:end] for subarray in solution_times],
    markershape=:xcross, 
    palette=ColorSchemes.Blues_5,
    legend=:bottomright,
    ylabel="Solution time (seconds)",
    xlabel="Number of constraints",
    xaxis=:log,
    yaxis=:log,
    xticks=([300, 1000, 3000, 10_000, 30_000, 100_000, 300_000], string.([300, 1000, 3000, 10_000, 30_000, 100_000, 300_000])),
    yticks=([0.1, 1, 10, 100, 1000], string.([0.1, 1, 10, 100, 1000])),
    label=["Depth 3 normal" "Depth 5 normal" "Depth 7 normal" "Depth 9 normal" "Depth 12 normal"],
    title="Optimization performance for "*dataset*" dataset"
)

plot!(
    [subarray[2:end] for subarray in number_of_added_cons],
    [subarray[2:end] for subarray in solution_times_alg],
    markershape=:xcross, 
    palette=ColorSchemes.Reds_5,
    label=["Depth 3 ConsGen" "Depth 5 ConsGen" "Depth 7 ConsGen" "Depth 9 ConsGen" "Depth 12 ConsGen"],
)

""" NUMBER OF TREES - OPT TIME """

plot(    
    map(len -> trees[1:len], length.([subarray[2:end] for subarray in solution_times])), 
    [subarray[2:end] for subarray in solution_times],
    markershape=:xcross, 
    palette=ColorSchemes.Blues_5,
    legend=:topright,
    yscale=:log10,
    ylabel="Solution time (seconds)",
    xlabel="Number of trees",
    label=["Depth 3 normal" "Depth 5 normal" "Depth 7 normal" "Depth 9 normal" "Depth 12 normal"],
    title="Optimization performance for "*dataset*" dataset"
)

plot!(
    map(len -> trees[1:len], length.([subarray[2:end] for subarray in solution_times_alg])), 
    [subarray[2:end] for subarray in solution_times_alg],
    markershape=:xcross, 
    palette=ColorSchemes.Reds_5,
    label=["Depth 3 ConsGen" "Depth 5 ConsGen" "Depth 7 ConsGen" "Depth 9 ConsGen" "Depth 12 ConsGen"],
)

""" NUMBER OF TREES - NUMBER OF CONSTRAINTS """

plot(    
    trees,
    [subarray[2:end] for subarray in number_of_init_cons],
    markershape=:xcross, 
    palette=ColorSchemes.Blues_5,
    legend=:topleft,
    ylabel="Number of constraints",
    xlabel="Number of trees",
    yticks=(collect(0:5).*50_000, string.(collect(0:5).*50_000)),
    label=["Depth 3" "Depth 5" "Depth 7" "Depth 9" "Depth 12"],
    title="Model scaling for "*dataset*" dataset"
)

plot!(
    trees,
    [subarray[2:end] for subarray in number_of_added_cons],
    markershape=:xcross, 
    palette=ColorSchemes.Reds_5,
    label=["Depth 3 ConsGen" "Depth 5 ConsGen" "Depth 7 ConsGen" "Depth 9 ConsGen" "Depth 12 ConsGen"],
)

for depth in depths
display(

pl.plot(   trees, 
            [solution_times[index[depth]][2:end] solution_times_alg[index[depth]][2:end]],
            markershape=:xcross, 
            palette=:rainbow,
            #yaxis=:log,
            legend=:topleft,
            #yticks=([0.1, 1, 10, 100, 1000], string.([0.1, 1, 10, 100, 1000])),
            ylabel="Solution time (seconds)",
            xlabel="Number of trees",
            label=["Normal depth $depth" "Algorithm depth $depth"],
            title="Optimization performance for "*dataset*" dataset"
        )
)
end

display(

pl.plot(    depths, 
            [[subarray[tree] for subarray in solution_times] for tree in 1:6],
            markershape=:xcross, 
            palette=:darktest,
            legend=:topleft,
            xticks=(depths, string.(depths)),
            ylabel="Solution time (seconds)",
            xlabel="Tree maximum depth",
            label=reshape(string.("Trees: ", trees)[1:end-1], 1, length(trees) - 1),
            title="Optimization performance for "*dataset*" dataset"
        )
)