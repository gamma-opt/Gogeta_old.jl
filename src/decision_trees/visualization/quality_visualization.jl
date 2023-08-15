import Plots as pl
using LaTeXStrings

datasets = ["concrete", "OX2", "3A4"];
stores = Dict([(3, 1), (5, 2), (7, 3), (9, 4), (12, 5)]);

pl.plot()

for dataset in datasets

parent_directory = "/Users/eetureijonen/Desktop/THESIS/ML_as_MO/src/decision_trees/";
filepath = parent_directory*"/test_results/"*dataset*"_test_results.txt";

elements = dataset == "3A4" ? 4 : 5;
depths = dataset == "3A4" ? [3, 5, 7, 9] : [3, 5, 7, 9, 12];

r2_test_values = Array{Array}(undef, elements);
[r2_test_values[depth] = [] for depth in 1:elements];

train_times = [];

trees = [10, 50, 100, 200, 350, 500, 750, 1000];

for line in eachline(filepath)

    if length(split(line, " ")) == 12 # lines with model qualty data

        n_trees = parse(Int, chop(split(line, " ")[4]));
        depth = parse(Int, chop(split(line, " ")[6]));
        r2_train = parse(Float64, chop(split(line, " ")[9]));
        r2_test = parse(Float64, chop(split(line, " ")[12]));

        push!(r2_test_values[stores[depth]], r2_test)

    elseif length(split(line, " ")) == 9 # lines with training time data

        n_trees = parse(Int, chop(split(line, " ")[4]));
        depth = parse(Int, chop(split(line, " ")[6]));
        train_time = parse(Float64, chop(split(line, " ")[9]));

        push!(train_times, train_time)
    end

end

display(
pl.plot(    trees[2:end], 
            palette=:rainbow,
            [subarray[2:end] for subarray in r2_test_values],
            markershape=:xcross,
            ylabel=L"R^{2}"*" for test data",
            xlabel="Number of trees",
            label=["Depth 3" "Depth 5" "Depth 7" "Depth 9" "Depth 12"],
            title="Model quality for "*dataset*" dataset "
        )
)
"""
display(
pl.plot!(   depths, 
            palette=:rainbow,
            train_times,
            yaxis=:log,
            legend=:bottomright,
            yticks=([0.1, 1, 10, 100, 1000, 10000], string.([0.1, 1, 10, 100, 1000, 10000])),
            xticks=([3, 5, 7, 9, 12], string.([3, 5, 7, 9, 12])),
            markershape=:xcross,
            ylabel="Training time",
            xlabel="Depth",
            label=dataset,
            title="Model training times"
        )
)
"""

end