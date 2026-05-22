using CSV, DataFrames

data_path = joinpath(@__DIR__, "breast_cancer.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "breast_cancer.csv")

col_names = [
    :class,
    :age,
    :menopause,
    :tumor_size,
    :inv_nodes,
    :node_caps,
    :deg_malig,
    :breast,
    :breast_quad,
    :irradiat
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

