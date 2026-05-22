using CSV, DataFrames

input_dir  = @__DIR__
output_dir = joinpath(@__DIR__, "..", "..", "dataframes")

mkpath(output_dir)

red_path   = joinpath(input_dir, "winequality-red.csv")
white_path = joinpath(input_dir, "winequality-white.csv")

red_df = CSV.read(
    red_path,
    DataFrame;
    missingstring="?",
    stripwhitespace=true,
)

white_df = CSV.read(
    white_path,
    DataFrame;
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(joinpath(output_dir, "winequality_red.csv"), red_df)
CSV.write(joinpath(output_dir, "winequality_white.csv"), white_df)
