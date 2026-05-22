using CSV, DataFrames

data_path = joinpath(@__DIR__, "heart_failure_clinical_records_dataset.csv")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "heart_failure_clinical_records.csv")

df = CSV.read(
    data_path,
    DataFrame;
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(df_path, df)