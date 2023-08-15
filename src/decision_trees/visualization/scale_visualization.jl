import Plots as pl

dataset = "concrete";
parent_directory = "/Users/eetureijonen/Desktop/THESIS/ML_as_MO/src/decision_trees/";

filepath = parent_directory*"/test_results/"*dataset*"_opt_results.txt";

filternums(text) = try parse(Float64, text) catch error NaN end;
colors = Dict([(3, "purple"), (5, "blue"), (7, "green"), (9, "orange"), (12, "red")]);

plot_data()

function plot_data()

    current_plot = pl.scatter()

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

            pl.scatter!(
                [init_cons], 
                [opt_time_normal], 
                markershape=:xcross, 
                label=:none,
                xaxis=:log10,
                yaxis=:log10,
                color="red"
            )

            pl.scatter!(    
                [added_cons], 
                [opt_time_normal], 
                markershape=:xcross, 
                label=:none,
                xaxis=:log10,
                yaxis=:log10,
                color="blue",
                ylabel="Solution time (seconds)",
                xlabel="Number of constraints",
                xticks=([300, 1000, 3000, 10_000, 30_000, 100_000, 300_000], string.([300, 1000, 3000, 10_000, 30_000, 100_000, 300_000])),
                yticks=([0.1, 1, 10, 100, 1000], string.([0.1, 1, 10, 100, 1000])),
                label=["Depth 3 normal" "Depth 5 normal" "Depth 7 normal" "Depth 9 normal" "Depth 12 normal"],
            )

        end
    end

    return current_plot
end