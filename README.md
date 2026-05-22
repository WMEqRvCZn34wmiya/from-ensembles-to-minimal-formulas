# CIKM 2026 - rules from random forests 

## Overview
This repository contains the experimental implementation for the paper "From ensembles to minimal formulas: A logic-driven framework to
explain symbolic ensemble models".

The experimental framework is designed to reproduce the results presented in the paper through two main experiments:
- Table 1 Generation: Dataset evaluation using F1-score analysis to determine optimal forest sizes (the dataset to remove is determined by the lowest F1-score across all forest sizes)
- accStudy Generation: Evaluation of the accuracy of the generated explanations across different datasets and model types (random forest, decision list, xgboost)
- Table 2 a Generation: Comprehensive comparison of LUMEN against state-of-the-art global explanation algorithms in the context of random forest models
- Table 2 b Generation: Comprehensive comparison of LUMEN against state-of-the-art global explanation algorithms in the context of decision list models
- Table 2 c Generation: Comprehensive comparison of LUMEN against state-of-the-art global explanation algorithms in the context of xgboost models

## Project Structure
```
.
├── src/
│   ├── table2.jl                                    # for random forest experiment
│   ├── table2_decisionlist.jl                       # for decision list experiment
│   ├── table2_xgboost.jl                            # for xgboost experiment
│   ├── suitfortest.jl     # only utils 
│   ├── utilsForTest.jl    # only utils 
│   └── datasetDirectory and more...
├── evaluation_results_experiment1.csv                # Will be generated
├── evaluation_results_experiment2.csv                # Will be generated
└── other ...
```

## Usage

```bash
# Import Julia's package manager
julia> import Pkg                     
# Install all dependencies specified in the Project.toml and Manifest.toml files
julia> Pkg.instantiate()                    
# Run your experiment script by replacing with your actual file path
julia> include("... insert here your experiment ...")  
```

## Supported Datasets
The framework supports the following datasets:
   - "car",                 
   - "hayes-roth",          
   - "tictactoe",           
   - "monks-3",             
   - "breast_cancer",       
   - "urinary-d1",          
   - "iris",                
   - "urinary-d2",          
   - "monks-1",             
   - "divorce",             
   - "soybean-small",       
   - "haberman",            
   - "mammographic_masses", 
   - "cryotherapy",         
   - "penguins",            
   - "occupancy",           
   - "house-votes",         
   - "htru2",               
   - "banknote",            
   - "seeds",               
   - "mushroom",            
   - "diabets"             

## Experiment Execution

### Experimenter 1: First Analysis Table Generation
1. Execute `tablet1.jl` to generate the first analysis table:
   
   ```bash
   julia> include("src/table1.jl")
   ```

### Experimenter 2: Second Analysis Table Generation
1. Execute `table2.jl` to generate the second analysis table:
   
   ```bash
   julia> include("src/table2.jl")
   ```
   ```bash
   julia> include("src/table2_decision_list.jl")
   ```
   ```bash
   julia> include("src/table2_xgboost.jl")
   ```

## Key Features
- Comprehensive evaluation of explanation algorithms across multiple datasets and model types
- Robust support for multiple datasets with automated preprocessing
- Detailed parameter sensitivity analysis
- Sophisticated rule generation and evaluation
- Precise performance metrics calculation

## Technical Details

## Requirements
- Julia programming environment (version 1.12.6)
- Python environment for RuleCosi+ algorithm