using CSV, DataFrames

data_path = joinpath(@__DIR__, "HTRU_2.csv")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "htru2.csv")

col_names = [
    :mean_integrated_profile,
    :std_integrated_profile,
    :excess_kurtosis_integrated_profile,
    :skewness_integrated_profile,
    :mean_dm_snr_curve,
    :std_dm_snr_curve,
    :excess_kurtosis_dm_snr_curve,
    :skewness_dm_snr_curve,
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