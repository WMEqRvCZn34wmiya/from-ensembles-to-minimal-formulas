"""
    element_to_string(x) -> String

Recursively convert a formula element to a human-readable string.

Supported input types:
- `Atom`: converts the wrapped scalar condition to a string like `"V3 ≥ 1.5"` or
  `"(V3 ≥ 1.5 ∧ V3 ≤ 3.0)"` for range conditions.
- `SyntaxBranch`: converts operator token and recursively processes child nodes.
- Any object with a `grandchildren` field (e.g., `LeftmostConjunctiveForm`):
  delegates to `leftmost_conjunctive_form_to_string`.
- Fallback: calls `string(x)`.

# Arguments
- `x`: A formula element — `Atom`, `SyntaxBranch`, `LeftmostConjunctiveForm`, or similar.

# Returns
A `String` representation of the element using logical notation (∧, ∨, ¬).

# Examples
```julia
element_to_string(Atom(cond))          # => "V2 ≥ 0.5"
element_to_string(branch_with_and)     # => "(V1 < 3.0 ∧ V2 ≥ 0.5)"
element_to_string(lcf)                 # => "(V1 < 3.0 ∧ V2 ≥ 0.5)"
```
"""
function element_to_string(x)
    if x isa Atom
        cond = x.value

        if cond isa SoleData.RangeScalarCondition
            # Range condition: encodes both a lower and upper bound on the same variable.
            # E.g., "1.0 ≤ V3 ≤ 5.0" is written as "(V3 ≥ 1.0 ∧ V3 ≤ 5.0)".
            i_var = cond.feature.i_variable
            lower_op = cond.minincluded ? "≥" : ">"   # inclusive or exclusive lower bound
            upper_op = cond.maxincluded ? "≤" : "<"   # inclusive or exclusive upper bound
            return "(" *
                   join(
                       [
                           "V$(i_var) $(lower_op) $(cond.minval)",
                           "V$(i_var) $(upper_op) $(cond.maxval)",
                       ],
                       " ∧ ",
                   ) *
                   ")"

        elseif hasproperty(cond, :metacond)
            # Standard scalar condition: a single comparison like "V3 < 2.5".
            # The variable index may already carry a "V" prefix (e.g., "V6"),
            # so we strip any leading "V" characters before re-adding the prefix
            # to avoid doubled labels like "VV6".
            i_var = cond.metacond.feature.i_variable
            i_var_str = replace(string(i_var), r"^V+" => "")   # strip accidental "V" prefix
            op_fun = cond.metacond.test_operator
            thr = cond.threshold

            # Map Julia comparison functions to their Unicode operator symbols.
            op_str =
                op_fun === (<) ? "<" :
                op_fun === (<=) ? "≤" :
                op_fun === (>) ? ">" :
                op_fun === (>=) ? "≥" : string(op_fun)   # fallback: use Julia's string()

            return "V$(i_var_str) $(op_str) $(thr)"

        else
            # Unknown condition type — use Julia's default string representation.
            return string(cond)
        end

    elseif x isa SyntaxBranch
        # A branch node: has a logical token (e.g., ∧, ∨, ¬) and one or more children.
        t = string(x.token)
        children_strs = map(element_to_string, x.children)

        if t == "¬"
            # Negation is a unary operator; only one child is expected.
            return "¬ " * children_strs[1]
        else
            # Binary operators (∧, ∨, etc.): join children with the operator,
            # and wrap the whole expression in parentheses for clarity.
            return "(" * join(children_strs, " " * t * " ") * ")"
        end

    elseif hasproperty(x, :grandchildren)
        # Handles LeftmostConjunctiveForm (and similar structures with a grandchildren field)
        # by delegating to the dedicated helper.
        return leftmost_conjunctive_form_to_string(x)

    else
        # Generic fallback for any other type.
        return string(x)
    end
end


"""
    leftmost_conjunctive_form_to_string(cf) -> String

Convert a `LeftmostConjunctiveForm` to a human-readable conjunction string.

Iterates over `cf.grandchildren`, converts each element via `element_to_string`,
and joins them with the `∧` (AND) operator, wrapping the result in parentheses.

# Arguments
- `cf`: A `LeftmostConjunctiveForm` (or any object with a `grandchildren` field
  containing iterable formula elements).

# Returns
A `String` such as `"(V1 < 2.0 ∧ V3 ≥ 0.5)"`.
"""
function leftmost_conjunctive_form_to_string(cf)
    return "(" * join(map(element_to_string, cf.grandchildren), " ∧ ") * ")"
end


"""
    atom_parser(a::String) -> Atom

Custom atom parser for use with `SoleLogics.parseformula`.

Parses a string representation of a scalar condition (e.g., `"V3 < 2.5"`) into an
`Atom` wrapping a `SoleData.ScalarCondition`, using `VariableValue` as the feature
type and `Real` as the value type.

This function is intended to be passed as the `atom_parser` keyword argument to
`SoleLogics.parseformula` so that propositional atoms in formula strings are correctly
interpreted as numeric variable conditions.

# Arguments
- `a::String`: A string encoding a scalar condition, e.g., `"V2 ≥ 1.0"`.

# Returns
An `Atom{ScalarCondition}`.
"""
atom_parser = function (a::String)
    return Atom(
        parsecondition(
            SoleData.ScalarCondition,
            a;
            featuretype=SoleData.VariableValue,
            featvaltype=Real,
        ),
    )
end


"""
    dnf_to_syntaxbranch(dnf_formula) -> SyntaxBranch or Atom

Convert a formula in Disjunctive Normal Form (DNF) to its `SyntaxBranch` representation.

Handles the following input types:
- `SyntaxBranch` — returned as-is (already in tree form).
- `Atom` — returned as-is (leaf node).
- `LeftmostLinearForm` — its `grandchildren` are treated as a list of disjuncts;
  each is converted via `conjunction_to_syntaxbranch` and they are folded with `∨`.
- `LeftmostConjunctiveForm` — treated as a single conjunction, delegated to
  `conjunction_to_syntaxbranch`.
- `Literal` — converted via `literal_to_syntaxbranch`.

# Arguments
- `dnf_formula`: A formula object in DNF.

# Returns
A `SyntaxBranch` (or `Atom`) representing the formula as a tree.

# Throws
- `ErrorException` if an unexpected formula type is encountered.
"""
function dnf_to_syntaxbranch(dnf_formula)
    if dnf_formula isa SyntaxBranch
        return dnf_formula

    elseif dnf_formula isa Atom
        return dnf_formula

    elseif dnf_formula isa LeftmostLinearForm
        # A LeftmostLinearForm encodes a disjunction of conjunctions.
        disjuncts = dnf_formula.grandchildren
        if length(disjuncts) == 1
            return conjunction_to_syntaxbranch(disjuncts[1])
        else
            # Fold the list of conjunctions into a right-leaning ∨ tree.
            return foldl(
                (a, b) -> SyntaxBranch(NamedConnective{:∨}(), (a, b)),
                map(conjunction_to_syntaxbranch, disjuncts),
            )
        end

    elseif dnf_formula isa LeftmostConjunctiveForm
        # A single conjunction — delegate directly.
        return conjunction_to_syntaxbranch(dnf_formula)

    elseif dnf_formula isa Literal
        return literal_to_syntaxbranch(dnf_formula)

    else
        error("Unexpected formula type: $(typeof(dnf_formula))")
    end
end


"""
    conjunction_to_syntaxbranch(conjunction) -> SyntaxBranch or Atom

Convert a conjunction (e.g., a `LeftmostConjunctiveForm`) to a `SyntaxBranch` tree.

Each child in the conjunction's `grandchildren` field is converted to a branch node
(handling `SyntaxBranch`, `Atom`, and `Literal` cases), and the results are folded
left-to-right using the `∧` connective.

# Arguments
- `conjunction`: A `LeftmostConjunctiveForm`, `SyntaxBranch`, `Atom`, or `Literal`.

# Returns
A single `SyntaxBranch` (for multi-literal conjunctions) or an `Atom`/`SyntaxBranch`
leaf (for singletons).
"""
function conjunction_to_syntaxbranch(conjunction)
    # Guard: if the input is already a leaf or branch, return it directly.
    if conjunction isa SyntaxBranch
        return conjunction
    elseif conjunction isa Atom
        return conjunction
    elseif conjunction isa Literal
        return literal_to_syntaxbranch(conjunction)
    end

    # LeftmostConjunctiveForm: grandchildren may be Atom, Literal, or SyntaxBranch.
    literals = conjunction.grandchildren

    # Helper: promote any child to a SyntaxBranch (or Atom) node.
    function to_branch(x)
        if x isa SyntaxBranch
            return x
        elseif x isa Atom
            return x
        else
            # Assume it is a Literal.
            return literal_to_syntaxbranch(x)
        end
    end

    if length(literals) == 1
        return to_branch(literals[1])
    else
        # Fold into a left-leaning ∧ tree.
        return foldl(
            (a, b) -> SyntaxBranch(NamedConnective{:∧}(), (a, b)),
            map(to_branch, literals),
        )
    end
end


"""
    literal_to_syntaxbranch(literal) -> SyntaxBranch or Atom

Convert a `Literal` to its `SyntaxBranch` representation.

Positive literals are unwrapped to their underlying `Atom`.
Negative literals are wrapped in a unary `¬` `SyntaxBranch`.

# Arguments
- `literal`: A `Literal` object with fields `ispos::Bool` and `atom::Atom`.

# Returns
- The bare `Atom` if the literal is positive.
- A `SyntaxBranch(¬, (atom,))` if the literal is negative.
"""
function literal_to_syntaxbranch(literal)
    if literal.ispos
        # Positive literal — the atom itself is the formula.
        return literal.atom
    else
        # Negative literal — negate the atom with the ¬ connective.
        return SyntaxBranch(NamedConnective{:¬}(), (literal.atom,))
    end
end


"""
    antecedent_to_string(antecedent) -> String

Convert the antecedent of a classification rule to a human-readable conjunction string.

Iterates over the atoms in `antecedent.grandchildren`, extracts each atom's feature
index, comparison operator, and threshold, and formats them as `"(Vk op thr)"` strings
joined by `∧`.

# Arguments
- `antecedent`: A `LeftmostConjunctiveForm` whose grandchildren are `Atom` objects
  wrapping `ScalarCondition` values.

# Returns
A `String` such as `"(V1 < 3.0) ∧ (V2 ≥ 0.5)"`.

# Notes
This function assumes all atoms are standard scalar conditions (not range conditions).
"""
function antecedent_to_string(antecedent)
    atoms = antecedent.grandchildren
    parts = String[]

    for atom in atoms
        cond = atom.value
        feat = cond.metacond.feature.i_variable
        op = cond.metacond.test_operator
        thr = cond.threshold

        op_str =
            op === (<) ? "<" :
            op === (<=) ? "≤" :
            op === (>) ? ">" :
            op === (>=) ? "≥" : string(op)

        push!(parts, "(V$feat $op_str $thr)")
    end

    return join(parts, " ∧ ")
end


"""
    _build_conjunction(atoms::Vector) -> SyntaxBranch or Atom

Build a left-leaning `∧` tree from a non-empty vector of atoms.

# Arguments
- `atoms::Vector`: A non-empty collection of `Atom` (or `SyntaxBranch`) nodes.

# Returns
A single node if `length(atoms) == 1`, otherwise a nested `SyntaxBranch` tree
folded left-to-right with `∧`.

# Throws
- `ErrorException` if `atoms` is empty.
"""
function _build_conjunction(atoms::Vector)
    if isempty(atoms)
        error("Cannot build conjunction from empty atom list")
    elseif length(atoms) == 1
        return atoms[1]
    else
        return foldl((a, b) -> SyntaxBranch(NamedConnective{:∧}(), (a, b)), atoms)
    end
end


"""
    _build_disjunction(formulas::Vector) -> SyntaxBranch or Atom

Build a left-leaning `∨` tree from a non-empty vector of formula nodes.

# Arguments
- `formulas::Vector`: A non-empty collection of formula nodes (`Atom`, `SyntaxBranch`, etc.).

# Returns
A single node if `length(formulas) == 1`, otherwise a nested `SyntaxBranch` tree
folded left-to-right with `∨`.

# Throws
- `ErrorException` if `formulas` is empty.
"""
function _build_disjunction(formulas::Vector)
    if isempty(formulas)
        error("Cannot build disjunction from empty formula list")
    elseif length(formulas) == 1
        return formulas[1]
    else
        return foldl((a, b) -> SyntaxBranch(NamedConnective{:∨}(), (a, b)), formulas)
    end
end


"""
    _atoms_from_antecedent(antecedent) -> Vector

Extract the list of `Atom` objects from a `LeftmostConjunctiveForm` antecedent.

# Arguments
- `antecedent`: A `LeftmostConjunctiveForm` (or any object with a `grandchildren` field).

# Returns
A `Vector` of the grandchildren (typically `Atom` instances).
"""
function _atoms_from_antecedent(antecedent)
    return collect(antecedent.grandchildren)
end


"""
    MyRule

A lightweight wrapper that pairs a parsed logical formula with a class label.

# Fields
- `formula::Formula`: The antecedent of the rule, stored as a parsed `Formula` object.
- `outcome::String`: The class label (consequent) associated with this rule.

# Notes
`MyRule` is used internally when building and manipulating DNF rule sets before
converting them to the library's native `Rule` type.
"""
struct MyRule
    formula::Formula   # Parsed antecedent formula
    outcome::String    # Class label (consequent)
end


"""
    build_dnf_rules(ll::Vector) -> Vector{Rule}

Convert an ordered decision list into a set of DNF rules grouped by outcome class.

Decision lists have *sequential semantics*: rule `i` only fires when all preceding
rules did **not** match. This function makes those implicit conditions explicit by
prepending the negation of every earlier antecedent to each rule's antecedent:

    real_antecedent_i = antecedent_i ∧ ¬antecedent_1 ∧ … ∧ ¬antecedent_{i-1}

After expanding each modified antecedent into full DNF (via De Morgan's laws and
distributivity), the results are grouped by outcome. Rules for the same outcome are
joined with `∨`, and the union is simplified to DNF once more.

# Arguments
- `ll::Vector`: An ordered list of `ClassificationRule` (or compatible) objects.
  Each element must expose:
  - `rule.consequent.outcome` — the class label.
  - `rule.antecedent` — a `LeftmostConjunctiveForm` or `SyntaxBranch`.

# Returns
A `Vector{Rule}` sorted lexicographically by outcome, where each `Rule` has:
- A DNF antecedent that correctly accounts for the decision-list ordering.
- The associated class label as its consequent.

# Algorithm
1. Iterate over rules in order, maintaining a list of previously seen antecedents.
2. For each rule, build the "real" antecedent by conjoining it with the negation
   of all previous antecedents.
3. Expand immediately to DNF to handle `¬(A ∧ B) → (¬A ∨ ¬B)`.
4. Accumulate expanded antecedents per outcome class.
5. Disjoin all antecedents for each outcome, expand to DNF again, and wrap in a `Rule`.
"""
function build_dnf_rules(ll::Vector)
    # Maps outcome label → list of expanded DNF antecedent branches for that class.
    class_to_formulas = Dict{String,Vector}()

    # Accumulates the SyntaxBranch antecedents of all rules processed so far.
    previous_antecedents = []

    for rule in ll
        outcome = string(rule.consequent.outcome)
        ant = rule.antecedent

        # Ensure the antecedent is in SyntaxBranch form for manipulation.
        ant_branch = ant isa SyntaxBranch ? ant : dnf_to_syntaxbranch(ant)

        # Build the real antecedent:
        #   real_ant = ant ∧ ¬prev_1 ∧ ¬prev_2 ∧ …
        # Each ¬prev_k term is expanded immediately via dnf() to apply De Morgan:
        #   ¬(A ∧ B) → (¬A ∨ ¬B)
        # and to distribute ∧ over ∨ so the result stays in proper DNF.
        real_ant = ant_branch
        for prev in previous_antecedents
            neg_prev = SyntaxBranch(NamedConnective{:¬}(), (prev,))
            real_ant = SyntaxBranch(NamedConnective{:∧}(), (real_ant, neg_prev))
        end

        # Fully expand to DNF.
        real_ant_dnf = dnf(real_ant)
        real_ant_branch = dnf_to_syntaxbranch(real_ant_dnf)

        # Register the expanded antecedent under its outcome class.
        push!(get!(class_to_formulas, outcome, []), real_ant_branch)

        # Record the original (unmodified) antecedent for future negations.
        push!(previous_antecedents, ant_branch)
    end

    minimized_rules = Rule[]

    # For each outcome (sorted for deterministic output), disjoin all antecedents,
    # re-expand to DNF, and emit a single Rule.
    for (outcome, formulas) in sort(collect(class_to_formulas), by=first)
        φ_raw = _build_disjunction(formulas)   # OR all antecedents for this class
        φ_dnf = dnf(φ_raw)                     # expand again to ensure proper DNF
        φ_branch = dnf_to_syntaxbranch(φ_dnf)     # convert back to SyntaxBranch
        push!(minimized_rules, Rule(φ_branch, outcome))
    end

    return minimized_rules
end


"""
    convertApi(f) -> DecisionSet

Convert a decision forest/tree `f` into a `DecisionSet` of DNF rules.

This is the main entry point for the conversion pipeline:
1. Extracts a flat decision list from `f` using `listrules` with
   `use_shortforms=false`, so that every root-to-leaf path becomes a separate
   rule containing only pure atom conjunctions (no negations of compound blocks).
2. Converts the ordered decision list into DNF rules that respect sequential
   semantics via `build_dnf_rules`.
3. Wraps the resulting rules in a `DecisionSet`.

# Arguments
- `f`: A fitted model (decision tree, forest, etc.) compatible with `listrules`.

# Returns
A `DecisionSet` whose rules together cover the same input space as `f`, expressed
in Disjunctive Normal Form with explicit sequential-exclusion conditions.

# Notes
- Setting `use_shortforms=false` avoids negations of compound sub-formulas at the
  rule-extraction stage, keeping antecedents as simple atom conjunctions that are
  easier to negate and expand in `build_dnf_rules`.
- The resulting `DecisionSet` is **not** a decision list; all rules are evaluated
  independently (standard DNF semantics).
"""
function convertApi(f)
    # Extract one rule per root-to-leaf path; antecedents are pure atom conjunctions.
    ll = listrules(f, use_shortforms=false)

    # Build DNF rules that correctly encode decision-list sequential semantics.
    minimized_rules = build_dnf_rules(ll)

    return DecisionSet(minimized_rules)
end