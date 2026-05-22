using CSV, DataFrames

data_path = joinpath(@__DIR__, "fertility.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "fertility.csv")

col_names = [
    :season,
    :age,
    :childish_diseases,
    :accident_or_trauma,
    :surgical_intervention,
    :high_fevers_last_year,
    :alcohol_consumption,
    :smoking_habit,
    :sitting_hours,
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