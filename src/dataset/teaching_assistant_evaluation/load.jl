using CSV, DataFrames

data_path = joinpath(@__DIR__, "tae.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "teaching_assistant_evaluation.csv")

mkpath(dirname(df_path))

col_names = [
    :native_english_speaker,
    :course_instructor,
    :course,
    :semester,
    :class_size,
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