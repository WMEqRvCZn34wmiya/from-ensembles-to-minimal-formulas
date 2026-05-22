using CSV, DataFrames

data_path = joinpath(@__DIR__, "iranian-churn.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "iranian-churn.csv")

col_names = [
    :call_failure,
    :complains,
    :subscription_length,
    :charge_amount,
    :seconds_of_use,
    :frequency_of_use,
    :frequency_of_sms,
    :distinct_called_numbers,
    :age_group,
    :tariff_plan,
    :status,
    :age,
    :customer_value,
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