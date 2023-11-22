using Flux
using Flux: crossentropy, params, onehotbatch, onecold, throttle, train!, logitcrossentropy
using Flux.Data: DataLoader
using MLDatasets
using Statistics
using NPZ

include("./lossless_compression.jl")
include("../bound_tightening.jl")

const gurobi_env = Gurobi.Env()
const rng = MersenneTwister(1234)

function kaiming_initialization(out, inp)
  scaling = sqrt(2.0 / inp) |> Float64
  return scaling * randn(rng, Float64, (Int64(out), Int64(inp)))
end

function println_red(message)
  error = "\033[91m"
  reset = "\033[0m"
  println("$error$message$reset")
end

function println_cyan(message)
  cyan = "\033[96m"
  reset = "\033[0m"
  println("$cyan$message$reset")
end

function create_model(n_neurons, subdir_path)
  weight_paths = [joinpath(subdir_path, "layer_$(i)_weights.npy") for i in 0:4]
  bias_paths = [joinpath(subdir_path, "layer_$(i)_biases.npy") for i in 0:4]

  layers = []
  for i in 1:length(n_neurons)-2
      W = Float64.(npzread(weight_paths[i]))
      b = Float64.(npzread(bias_paths[i]))

      push!(layers, Dense(W, b, relu))
  end
  W_final = Float64.(npzread(weight_paths[end]))
  b_final = Float64.(npzread(bias_paths[end]))
  push!(layers, Dense(W_final, b_final))

  model = Chain(layers...)

  for p in params(model)
    p[abs.(p) .< 1e-7] .= 0
  end

  num = 0
  for p in params(model)
    num += sum(p .== 0)
  end
  println("Number of zeros: $num")

  return model
end

function get_bounds(subdir_path)
  upper = npzread(joinpath(subdir_path, "upper_new_lp.npy"))
  lower = npzread(joinpath(subdir_path, "lower_new_lp.npy"))

  return upper, lower
end

function find_lp_bounds(n_neurons, parent_dir)
  subdirs = filter(d -> isdir(joinpath(parent_dir, d)), readdir(parent_dir))
  n_neurons_initial = sum(n_neurons)

  for subdir in subdirs
    subdir_path = joinpath(parent_dir, subdir)
    println("Test with $subdir_path")

    model = create_model(n_neurons, subdir_path)

    U_bounds = Float64[-0.5, 0.5, [1000000 for _ in 3:n_neurons_initial]...]
    L_bounds = Float64[-1.5, -0.5, [-1000000 for _ in 3:n_neurons_initial]...]

    demo3_best_U_bounds, demo3_best_L_bounds = bound_tightening(model, U_bounds, L_bounds, false, true, gurobi_env)

    npzwrite(joinpath(subdir_path, "upper_new_lp.npy"), demo3_best_U_bounds)
    npzwrite(joinpath(subdir_path, "lower_new_lp.npy"), demo3_best_L_bounds)
  end
end

# find_lp_bounds(n_neurons, parent_dir)

# function test_lp_bounds(n_neurons, parent_dir)
# n_neurons_initial = sum(n_neurons)
# subdirs = filter(d -> isdir(joinpath(parent_dir, d)), readdir(parent_dir))
# subdir = subdirs[1]

# lp_lower = npzread(joinpath(parent_dir, subdir, "lower_new_lp.npy"))
# lp_upper = npzread(joinpath(parent_dir, subdir, "upper_new_lp.npy"))

# model = create_model(n_neurons, joinpath(parent_dir, subdir))

# U_bounds = Float64[-0.5, 0.5, [1000000 for _ in 3:n_neurons_initial]...]
# L_bounds = Float64[-1.5, -0.5, [-1000000 for _ in 3:n_neurons_initial]...]

# # # Either create or load the threaded bounds
# # upper_threads, lower_threads = bound_tightening_threads_old(model, U_bounds, L_bounds)
# # npzwrite(joinpath(parent_dir, subdir, "upper_new_threads.npy"), upper_threads)
# # npzwrite(joinpath(parent_dir, subdir, "lower_new_threads.npy"), lower_threads)
# upper_threads = npzread(joinpath(parent_dir, subdir, "upper_new_threads.npy"))
# lower_threads = npzread(joinpath(parent_dir, subdir, "lower_new_threads.npy"))

# difference_U1 = (lp_upper - upper_threads)[3:1026]
# difference_U2 = (lp_upper - upper_threads)[1027:1538]

# difference_L1 = (lp_lower - lower_threads)[3:1026]
# difference_L2 = (lp_lower - lower_threads)[1027:1538]

# println("$(maximum(difference_U1)), $(minimum(difference_U1))")
# println("$(maximum(difference_U2)), $(minimum(difference_U2))")
# println("$(maximum(difference_L1)), $(minimum(difference_L1))")
# println("$(maximum(difference_L2)), $(minimum(difference_L2))")

# # test stability around 0 (second layer) (should not print anything)
# for i in 1027:1538
#   if lp_upper[i] > 1e-5 && upper_threads[i] < -1e-5
#     println("$(i): $(lp_upper[i]), $(upper_threads[i])")
#   elseif lp_upper[i] < -1e-5 && upper_threads[i] > 1e-5
#     println("$(i): $(lp_upper[i]), $(upper_threads[i])")
#   end
# end



# constants
n_neurons = Int64[2, 1024, 512, 512, 256, 1]
n_neurons_cumulative_indices = [i+1 for i in [0, cumsum(n_neurons)...]]
parent_dir = "/Users/vimetoivonen/code/school/kandi/train_network/layer_weights"
# parent_dir = joinpath(dirname(dirname(@__FILE__)), "compression", "layer_weights")
subdirs = filter(d -> isdir(joinpath(parent_dir, d)), readdir(parent_dir))

pruned_neurons = []

for (i, subdir) in enumerate(subdirs)
  # i, subdir = 1, subdirs[4]
  subdir_path = joinpath(parent_dir, subdir)
  println("Test with $subdir_path")

  model = create_model(n_neurons, subdir_path)
  n_parameters_model = sum(length, params(model))

  upper, lower = get_bounds(subdir_path)

  # calculate the upper and lower bounds for each layer
  upper_bounds = [upper[i:j-1] for (i, j) in zip(n_neurons_cumulative_indices[1:end-1], n_neurons_cumulative_indices[2:end])][2:end]
  lower_bounds = [lower[i:j-1] for (i, j) in zip(n_neurons_cumulative_indices[1:end-1], n_neurons_cumulative_indices[2:end])][2:end]
  println("The bound lengths: $(map(x -> length(x), upper_bounds))")



  # ! ######################################## ! #
  # ! # Setup done now we can start pruning  # ! #
  # ! ######################################## ! #



  model_params = params(model)
  weights = [copy(model_params[i]) for i in 1:2:length(model_params)]
  biases = [copy(model_params[i]) for i in 2:2:length(model_params)]

  # TODO: fix warning
  pruned_weights = [copy(weights[i]) for i in 1:length(weights)]
  pruned_biases = [copy(biases[i]) for i in 1:length(biases)]


  for param_index in 1:length(weights)-1
      W1 = copy(pruned_weights[param_index])
      b1 = copy(pruned_biases[param_index])

      W2 = copy(weights[param_index+1])
      b2 = copy(biases[param_index+1])

      upper1 = copy(upper_bounds[param_index])
      upper2 = copy(upper_bounds[param_index+1])
      lower1 = copy(lower_bounds[param_index])
      lower2 = copy(lower_bounds[param_index+1])

      x = param_index == 1 ? [-1, 0] : rand(rng, Float64, size(W1, 2))
      _, a2_original = forward_pass(x, W1, b1, W2, b2)

      # prune the layer
      W1_pruned, b1_pruned, W2_pruned, b2_pruned, n_pruned_by_upper_bound, n_pruned_by_zero_weight, n_pruned_by_linear_dependence = prune_from_model(W1, b1, W2, b2, upper1, upper2, lower1, lower2)

      println_cyan("Pruned: $(n_pruned_by_upper_bound) by U, $(n_pruned_by_zero_weight) by W, $(n_pruned_by_linear_dependence) by dependence")

      _, a2_pruned = forward_pass(x, W1_pruned, b1_pruned, W2_pruned, b2_pruned)
      difference = a2_original - a2_pruned

      if maximum(abs.(difference)) > 1e-5
          println_red("The difference between the forward passes: $(maximum(abs.(difference)))")
      end

      pruned_weights[param_index] = copy(W1_pruned)
      pruned_biases[param_index] = copy(b1_pruned)

      pruned_weights[param_index+1] = copy(W2_pruned)
      pruned_biases[param_index+1] = copy(b2_pruned)
  end

  # recreate the model
  n_neurons_pruned = [2, map(x -> size(x, 1), pruned_weights)...]
  pruned_layers = []
  for i = 1:length(n_neurons_pruned)-2
      W = pruned_weights[i]
      b = pruned_biases[i]
      layer = Dense(W, b, relu)
      push!(pruned_layers, layer)
  end
  W_final = pruned_weights[end]
  b_final = pruned_biases[end]
  push!(pruned_layers, Dense(W_final, b_final))

  model_pruned = Chain(pruned_layers...)
  println("The new architecture: $n_neurons_pruned")
  n_parameters_model_pruned = sum(length, params(model_pruned))

  # create 10 numbers randomly x1 from [-1.5, -0.5] and x2 from [-0.5, 0.5]
  x1 = rand(rng, Float32, 10) .- 1.5
  x2 = rand(rng, Float32, 10) .- 0.5
  x = hcat(x1, x2)'

  # forward pass through the original model
  y = model(x)
  y_pruned = model_pruned(x)
  difference = y - y_pruned

  push!(pruned_neurons, sum(n_neurons) - sum(n_neurons_pruned))

  println("The min and max difference: $(round(minimum(difference), sigdigits=3)), $(round(maximum(difference), sigdigits=3))")
  println("Pruned successfully: $(all(abs.(difference) .< 1e-3) ? "✅" : "🚫")")
  println("Number of neurons pruned: $(sum(n_neurons) - sum(n_neurons_pruned)) ($(round(100 * (sum(n_neurons) - sum(n_neurons_pruned)) / sum(n_neurons), sigdigits=3))%)")
  println("Number of parameters pruned: $(n_parameters_model - n_parameters_model_pruned) ($(round(100 * (n_parameters_model - n_parameters_model_pruned) / n_parameters_model, sigdigits=3))%)")
end


println_cyan("On average, we pruned: $(round(mean(pruned_neurons), sigdigits=3)) neurons, which is $(round(100 * mean(pruned_neurons) / sum(n_neurons), sigdigits=3))% of the neurons")
