using CSV, DataFrames

data_path = joinpath(@__DIR__, "diagnosis.data")
out_dir   = joinpath(@__DIR__, "..", "..", "dataframes")

col_names = [
    :a1_temperature,
    :a2_nausea,
    :a3_lumbar_pain,
    :a4_urine_pushing,
    :a5_micturition_pains,
    :a6_urethra_problem,
    :d1, # Inflammation of urinary bladder
    :d2, # Nephritis of renal pelvis origin
]

df = CSV.read(
    data_path,
    DataFrame;
    header = col_names,
    missingstring="?",
    stripwhitespace=true,
)

# Dataset 1: only d1 as target
df_d1 = select(df, Not(:d2))
rename!(df_d1, :d1 => :class)

# Dataset 2: only d2 as target
df_d2 = select(df, Not(:d1))
rename!(df_d2, :d2 => :class)

mkpath(out_dir)
CSV.write(joinpath(out_dir, "diagnosis_d1.csv"), df_d1)
CSV.write(joinpath(out_dir, "diagnosis_d2.csv"), df_d2)

