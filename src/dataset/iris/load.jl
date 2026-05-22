using CSV, DataFrames

data_path = joinpath(@__DIR__, "iris.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "iris.csv")

col_names = [
    :sepal_length,
    :sepal_width,
    :petal_length,
    :petal_width,
    :class,
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(df_path, df)