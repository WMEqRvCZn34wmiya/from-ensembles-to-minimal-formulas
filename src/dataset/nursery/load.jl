using CSV, DataFrames

data_path = joinpath(@__DIR__, "nursery.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "nursery.csv")

col_names = [
    :parents,
    :has_nurs,
    :form,
    :children,
    :housing,
    :finance,
    :social,
    :class
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

# Keep class as last column
select!(df, Not(:class), :class)

CSV.write(df_path, df)