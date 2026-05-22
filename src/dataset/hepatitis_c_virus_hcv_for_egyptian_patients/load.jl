using CSV, DataFrames

data_path = joinpath(@__DIR__, "HCV-Egy-Data.csv")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "hcv_egyptian_patients.csv")

# Read CSV with its existing header row
df = CSV.read(
    data_path,
    DataFrame;
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(df_path, df)