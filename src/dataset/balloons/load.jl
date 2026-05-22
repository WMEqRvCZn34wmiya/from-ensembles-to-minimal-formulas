using CSV, DataFrames

data_path = joinpath(@__DIR__, "balloons-all.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "balloons-all.csv")

col_names = [
    :color,
    :size,
    :action,
    :age,
    :class,
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

select!(df, Not(:class), :class)
CSV.write(df_path, df)