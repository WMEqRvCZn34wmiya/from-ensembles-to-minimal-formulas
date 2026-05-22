using CSV, DataFrames

data_path = joinpath(@__DIR__, "diabetes_data_upload.csv")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "early_stage_diabetes_risk_prediction_dataset.csv")

df = CSV.read(
    data_path,
    DataFrame;
    missingstring="?",
    stripwhitespace=true,
)

CSV.write(df_path, df)