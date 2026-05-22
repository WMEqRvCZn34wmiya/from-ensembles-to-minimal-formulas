using CSV, DataFrames

data_path = joinpath(@__DIR__, "hayes-roth.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "hayes-roth.csv")

col_names = [
    :name,
    :hobby,
    :age,
    :educational_level,
    :marital_status,
    :class,
]

df = CSV.read(
    data_path,
    DataFrame;
    header = col_names,
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(df_path, df)