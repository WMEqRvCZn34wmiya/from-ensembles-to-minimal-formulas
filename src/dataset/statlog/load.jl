using CSV, DataFrames

data_path = joinpath(@__DIR__, "statlog.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "statlog.csv")

col_names = [
    :age,
    :sex,
    :chest_pain,
    :resting_bp,
    :serum_chol,
    :fasting_blood_sugar,
    :resting_ecg,
    :max_heart_rate,
    :exercise_induced_angina,
    :oldpeak,
    :slope,
    :ca,
    :thal,
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