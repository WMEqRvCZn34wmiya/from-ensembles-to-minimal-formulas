using CSV, DataFrames

data_path = joinpath(@__DIR__, "haberman.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "haberman.csv")

col_names = [
    :age,
    :year_of_operation,
    :positive_axillary_nodes,
    :class,  # 1 = survived 5+ years, 2 = died within 5 years
]

df = CSV.read(
    data_path,
    DataFrame;
    header = col_names,
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(df_path, df)