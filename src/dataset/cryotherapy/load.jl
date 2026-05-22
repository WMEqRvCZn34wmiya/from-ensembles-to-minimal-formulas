using CSV, DataFrames

data_path = joinpath(@__DIR__, "cryotherapy.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "cryotherapy.csv")

col_names = [
    :sex,
    :age,
    :time,
    :number_of_warts,
    :type,
    :area,
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