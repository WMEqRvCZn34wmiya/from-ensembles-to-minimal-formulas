using CSV, DataFrames

data_path = joinpath(@__DIR__, "heart.dat")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "statlog_heart.csv")

col_names = [
    :age,
    :sex,
    :chest_pain_type,
    :resting_blood_pressure,
    :serum_cholesterol_mg_dl,
    :fasting_blood_sugar_gt_120,
    :resting_ecg_results,
    :max_heart_rate_achieved,
    :exercise_induced_angina,
    :oldpeak,
    :slope_peak_exercise_st_segment,
    :num_major_vessels,
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