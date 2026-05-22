using CSV, DataFrames

data_path = joinpath(@__DIR__, "tictactoe.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "tictactoe.csv")

col_names = [
    :top_left_square,
    :top_middle_square,
    :top_right_square,
    :middle_left_square,
    :middle_middle_square,
    :middle_right_square,
    :bottom_left_square,
    :bottom_middle_square,
    :bottom_right_square,
    :class,  # positive / negative
]

df = CSV.read(
    data_path,
    DataFrame;
    header = col_names,
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(df_path, df)