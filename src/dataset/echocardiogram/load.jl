using CSV, DataFrames

data_path = joinpath(@__DIR__, "echocardiogram.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "echocardiogram.csv")

col_names = [
    :survival,
    :still_alive,
    :age_at_heart_attack,
    :pericardial_effusion,
    :fractional_shortening,
    :epss,
    :lvdd,
    :wall_motion_score,
    :wall_motion_index,
    :mult,
    :name,
    :group,
    :class,   # alive-at-1 (already last)
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

select!(df, Not(:name))
CSV.write(df_path, df)