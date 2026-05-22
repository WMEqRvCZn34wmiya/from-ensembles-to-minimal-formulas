using CSV, DataFrames

data_path = joinpath(@__DIR__, "house-votes.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "house-votes-84.csv")

col_names = [
    :class,  # first in raw file
    :handicapped_infants,
    :water_project_cost_sharing,
    :adoption_of_the_budget_resolution,
    :physician_fee_freeze,
    :el_salvador_aid,
    :religious_groups_in_schools,
    :anti_satellite_test_ban,
    :aid_to_nicaraguan_contras,
    :mx_missile,
    :immigration,
    :synfuels_corporation_cutback,
    :education_spending,
    :superfund_right_to_sue,
    :crime,
    :duty_free_exports,
    :export_administration_act_south_africa,
]

df = CSV.read(
    data_path,
    DataFrame;
    header = col_names,
    missingstring="?",
    stripwhitespace=true,
)

# move class to last position
select!(df, Not(:class), :class)

CSV.write(df_path, df)