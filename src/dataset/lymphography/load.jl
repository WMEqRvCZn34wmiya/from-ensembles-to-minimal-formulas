using CSV, DataFrames

data_path = joinpath(@__DIR__, "lymphography.data")
df_path   = joinpath(@__DIR__, "..", "..", "dataframes", "lymphography.csv")

col_names = [
    :class,
    :lymphatics,
    :block_of_affere,
    :bl_of_lymph_c,
    :bl_of_lymph_s,
    :by_pass,
    :extravasates,
    :regeneration_of,
    :early_uptake_in,
    :lym_nodes_dimin,
    :lym_nodes_enlar,
    :changes_in_lym,
    :defect_in_node,
    :changes_in_node,
    :changes_in_stru,
    :special_forms,
    :dislocation_of,
    :exclusion_of_no,
    :no_of_nodes_in,
]

df = CSV.read(
    data_path,
    DataFrame;
    header=col_names,
    missingstring="?",
    stripwhitespace=true,
)

select!(df, Not(:class), :class)
CSV.write(df_path, df)