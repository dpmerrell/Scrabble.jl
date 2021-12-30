
import Base: iterate


mutable struct SubBagIter
    bag::Bag
    k::Int
    child::Union{Nothing,SubBagIter}
end


function SubBagIter(bag, k)
   return SubBagIter(bag, k, nothing)
end


########################
# HELPER FUNCTIONS
########################
function create_child_bag(bag, k, idx)
    child = Int[min(k, count) for count in bag[idx:end]]
    child[1] -= 1
    return child
end

function create_item(bag, idx)
    item = zero(bag)
    item[idx] += 1
    return item
end

function combine_items(bag, idx, child_item)
    item = create_item(bag, idx)
    item[idx:end] .+= child_item
    return item
end
    
function combine_states(idx, child_state)
    return [[idx]; child_state]
end

###################################
# ITERATOR INTERFACE DEFINITION
###################################
function iterate(sbi::SubBagIter)

    # No such subbags exist -- no items
    # to iterate through!
    if sum(sbi.bag) < sbi.k
        return nothing
    end

    # Otherwise, advance to the first nonzero entry
    # (which is guaranteed to exist)
    idx = 1
    while sbi.bag[idx] <= 0
        idx += 1
    end

    # Base case: k == 1 
    if sbi.k <= 1
        state = [idx]
        item = create_item(sbi.bag, idx) 
        return item, state
    end

    # Recursive case: k > 1

    # Create the "child" bag of remaining items and 
    # construct a child iterator to advance through it.
    child_bag = create_child_bag(sbi.bag, sbi.k, idx)
    sbi.child = SubBagIter(child_bag, sbi.k-1)

    # Call "iterate" on the child in order to initialize it.
    # Guaranteed to return (item, state) tuple, rather than nothing.
    child_item, child_state = iterate(sbi.child)

    # combine the child item with this iterator's item
    item = combine_items(sbi.bag, idx, child_item)
    state = combine_states(idx, child_state)

    return item, state
end


function iterate(sbi::SubBagIter, state)

    # Base case: k = 1
    if sbi.k == 1
        
        # Advance to the next nonzero entry
        idx = state[1]
        for (i, count) in enumerate(sbi.bag[idx+1:end])
            if count > 0
                idx += i
                break
            end
        end
        # If the idx is unchanged, then we've reached the end! return `nothing`
        if idx == state[1]
             return nothing
        else # Otherwise, return the current item and state
            item = create_item(sbi.bag, idx)
            state = [idx]
            return item, state
        end
    end

    # Recursive case: k > 1
    
    # Iterate the child
    child_result = iterate(sbi.child, state[2:end])

    # If the child returned (item, state),
    # then we return combined items/states
    if child_result != nothing
        child_item = child_result[1]
        child_state = child_result[2]

        item = combine_items(sbi.bag, state[1], child_item)
        state = combine_states(state[1], child_state)
        return item, state
    else
    # If the child returned `nothing`, then
    # we advance idx to the next nonzero entry
        idx = state[1]
        for (i, count) in enumerate(sbi.bag[idx+1:end])
            if count > 0
                idx += i
                break
            end
        end
        
        # If the idx was not updated, then we've run out of 
        # nonzero entries -- we're done!
        if idx == state[1]
            return nothing
        else
        # Otherwise, re-initialize the child at this new location 
            sbi.child.bag = create_child_bag(sbi.bag, sbi.k, idx)
            child_result = iterate(sbi.child)
           
            # If the re-initialized child returns nothing, 
            # then we're done! 
            if child_result == nothing
                return nothing
            end

            # Otherwise, we just return the next item/state
            child_item = child_result[1]
            child_state = child_result[2]
            item = combine_items(sbi.bag, idx, child_item)
            state = combine_states(idx, child_state)
            return item, state
        end
    end
end


#########################################
# Iterate through ALL subbags
#########################################

mutable struct AllSubBagIter
    bag::Bag
    subbag_iter::SubBagIter
end

function AllSubBagIter(bag::Bag)
    subbag_iter = SubBagIter(bag, 1)
    return AllSubBagIter(bag,subbag_iter)
end

function iterate(asbi::AllSubBagIter)

    # Construct subbag iterator; initialize it
    asbi.subbag_iter = SubBagIter(asbi.bag, 1)
    sbi_iter_result = iterate(asbi.subbag_iter)

    # If it returns nothing, then we're done!
    if sbi_iter_result == nothing
        return nothing
    end

    # Otherwise: return the split and the state
    sbi_item = sbi_iter_result[1]
    sbi_state = sbi_iter_result[2]

    sbi_complement = bag_complement(asbi.bag, sbi_item)
    return sbi_item, sbi_state
end


function iterate(asbi::AllSubBagIter, state)

    # Try to advance the subbag_iter
    sbi_iter_result = iterate(asbi.subbag_iter, state)

    # If we get "nothing",
    if sbi_iter_result == nothing 
        # then increment k
        asbi.subbag_iter.k = asbi.subbag_iter.k + 1

        # then reset and initialize the subbag_iter
        sbi_iter_result = iterate(asbi.subbag_iter)
       
        if sbi_iter_result == nothing
            return nothing
        end 
    end

    sbi_item = sbi_iter_result[1]
    sbi_state = sbi_iter_result[2]

    # return the split and the state (k, subbag_iter state)
    return sbi_item, sbi_state
end


#########################################
# Iterate through all possible "splits"
# of a bag
#########################################

mutable struct BagSplitIter
    bag::Bag
    N::BagType
    subbag_iter::SubBagIter
end

function BagSplitIter(bag)
    subbag_iter = SubBagIter(bag, 1)
    N = sum(bag)
    return BagSplitIter(bag, N, subbag_iter)
end

function count_subbags(bag, k)
    N = sum(bag)
    redundant = binomial(N,k)
    non_redundant = div(redundant, prod([factorial(b) for b in bag]))
end

function iterate(bsi::BagSplitIter)
    
    # Initialize the subbag_iter
    subbag_iter_result = iterate(bsi.subbag_iter)

    if subbag_iter_result == nothing
        return nothing
    end

    subbag_item = subbag_iter_result[1]
    subbag_state = subbag_iter_result[2]
    
    complement = bag_complement(bsi.bag, subbag_item)
    return (subbag_item, complement), ((false,-1,-1), subbag_state) 
end


function iterate(bsi::BagSplitIter, state)
   
    subbag_iter_state = state[2]
    middle_state = state[1]
 
    # Try iterating the subbag_iter
    subbag_iter_result = iterate(bsi.subbag_iter, subbag_iter_state)

    new_middle_state = (false,-1,-1)

    # If it returned nothing:
    if subbag_iter_result == nothing
        # Increment the iterator's `k`
        bsi.subbag_iter.k = bsi.subbag_iter.k + 1

        N_d_2 = div(bsi.N, 2)

        # Check k's size
        if bsi.subbag_iter.k >= N_d_2

            # If k is too large, we're done!
            if bsi.subbag_iter.k > N_d_2
                return nothing
            # Otherwise, we've reached the "middle size".
            # We need to start tracking our state in the 
            # middle size, to avoid redundancies.
            else 
                if N_d_2 % 2 == 0
                    max_iter = div(count_subbags(bsi.bag, bsi.subbag_iter.k), 2)
                    new_middle_state = (true, 1, max_iter)
                end 
            end
        end
        # Re-initialize the iterator
        subbag_iter_result = iterate(bsi.subbag_iter)
    end
    # If it returned (item, state)
    sub_item = subbag_iter_result[1]
    sub_state = subbag_iter_result[2]
    complement = bag_complement(bsi.bag, sub_item)

    # if we're in the "middle size", then
    # we need to update some additional state
    if middle_state[1]
        new_middle_state = (true, middle_state[2]+1, middle_state[3])
    end

    return (sub_item, complement), (new_middle_state, sub_state)
end


######################################
# Iterate through the decompositions
# encoded in a table
######################################

mutable struct DecompIter
    cache::Dict{Bag,Vector{Bag}}
    bag::Bag
    threshold::Bag
    sub_iter::Union{Nothing,DecompIter}
    depth::Int
end


function DecompIter(cache, bag::Bag, threshold::Bag)
    return DecompIter(cache, bag, threshold, nothing, 0)
end


function DecompIter(cache, bag::Bag, threshold::Bag, depth::Int)
    return DecompIter(cache, bag, threshold, nothing, depth)
end


function DecompIter(cache, bag)
    return DecompIter(cache, bag, zeros(BagType, N_CHAR))
end


function iterate(dci::DecompIter)

    # Base case: bag is empty
    if all(dci.bag .== 0)
        return Bag[], nothing
    end

    # Advance the child_idx to the first child with a valid decomposition.
    child_vec = dci.cache[dci.bag]
    child_idx = 1
    while child_idx <= length(child_vec)

        child = child_vec[child_idx]

        # The child must be >= the threshold, though
        if bag_leq(dci.threshold, child)
            complement = bag_complement(dci.bag, child)

            dci.sub_iter = DecompIter(dci.cache, complement, child, dci.depth+1) 
            sub_result = iterate(dci.sub_iter)

            if sub_result != nothing
                sub_item = sub_result[1]
                sub_state = sub_result[2]
                return [Bag[child]; sub_item], (child_idx, sub_state)
            end
        end

        # Otherwise, we move on to the next child 
        child_idx += 1
    end

    return nothing
end


function iterate(dci::DecompIter, state)

    # Base case: bag is empty
    if all(dci.bag .== 0)
        return nothing
    end

    # Otherwise: search for the next valid decomposition
    child_idx = state[1]
    sub_state = state[2]
    child_vec = dci.cache[dci.bag]

    # Try to iterate the sub_iter
    sub_result = iterate(dci.sub_iter, sub_state)
    if sub_result != nothing
        sub_item = sub_result[1]
        sub_state = sub_result[2]
        return [Bag[child_vec[child_idx]]; sub_item], (child_idx, sub_state)
    end

    # If the sub_iter terminates, advance the child index
    while true
        while true 
            child_idx += 1
            if child_idx > length(child_vec)
                return nothing
            end
            if bag_leq(dci.threshold, child_vec[child_idx])
                break
            end
        end

        # ...and update the sub_iter
        complement = bag_complement(dci.bag, child_vec[child_idx])
        dci.sub_iter = DecompIter(dci.cache, complement, child_vec[child_idx], dci.depth+1)
        sub_result = iterate(dci.sub_iter)
        
        if sub_result != nothing
            sub_item = sub_result[1]
            sub_state = sub_result[2]
            return [Bag[child_vec[child_idx]]; sub_item], (child_idx, sub_state)
        end
    end 

end

#################################
# Cartesian Product Iterator
#################################

mutable struct ProductIter
    collections::AbstractVector
    child::Union{Nothing,ProductIter}
end

function ProductIter(collections::AbstractVector)
    return ProductIter(collections, nothing)
end


function iterate(prit::ProductIter)
   
    # Base cases
    if length(prit.collections[1]) == 0
        return nothing
    end
    if length(prit.collections) == 1
        return [prit.collections[1][1]], (1, nothing)
    end

    # Recursive case
    prit.child = ProductIter(prit.collections[2:end])
    child_result = iterate(prit.child)
    if child_result == nothing
        return nothing
    else
        child_item = child_result[1]
        child_state = child_result[2]
        return [[prit.collections[1][1]] ; child_item], (1, child_state)
    end
end


function iterate(prit::ProductIter, state)

    cur_idx = state[1]
    child_state = state[2]

    # Base case
    if length(prit.collections) == 1
        cur_idx += 1
        if cur_idx > length(prit.collections[1])
            return nothing
        else
            return [prit.collections[1][cur_idx]], (cur_idx, nothing)
        end 
    end

    # Recursive case
    child_result = iterate(prit.child, child_state)
    if child_result != nothing
        child_item = child_result[1]
        child_state = child_result[2]
    else
        cur_idx += 1
        if cur_idx > length(prit.collections[1])
            return nothing
        end
        prit.child = ProductIter(prit.collections[2:end])
        child_item, child_state = iterate(prit.child)
    end
    return [prit.collections[1][cur_idx]; child_item], (cur_idx, child_state)
end


##########################################
# Anagram Iterator
##########################################

mutable struct AnagramIter
    bag::Bag
    decomp_cache::Dict{Bag,Vector{Bag}}
    decomp_iter::Union{Nothing,DecompIter}
    prod_iter::Union{Nothing,ProductIter}
end

function AnagramIter(bag::Bag, decomp_cache)
    return AnagramIter(bag, decomp_cache, nothing, nothing)
end 

function iterate(ani::AnagramIter)
    ani.decomp_iter = DecompIter(ani.decomp_cache, ani.bag) 
    decomp_result = iterate(ani.decomp_iter)
    if decomp_result == nothing
        return nothing
    end
    decomp_item = decomp_result[1]
    decomp_state = decomp_result[2]

    ani.prod_iter = ProductIter([VOCAB_DICT[bag] for bag in decomp_item])
    prod_result = iterate(ani.prod_iter)
    if prod_result == nothing
        return nothing
    end
    prod_item = prod_result[1]
    prod_state = prod_result[2]

    return prod_item, (decomp_state, prod_state)
end

function iterate(ani::AnagramIter, state)

    decomp_state = state[1]
    prod_state = state[2]

    prod_result = iterate(ani.prod_iter, prod_state)
    if prod_result == nothing
        decomp_result = iterate(ani.decomp_iter, decomp_state)
        if decomp_result == nothing
            return nothing
        else
            decomp_item = decomp_result[1]
            decomp_state = decomp_result[2]
            ani.prod_iter = ProductIter([VOCAB_DICT[bag] for bag in decomp_item])
     
            prod_result = iterate(ani.prod_iter) 
            if prod_result == nothing
                return nothing
            end
            prod_item = prod_result[1]
            prod_state = prod_result[2]
            return prod_item, (decomp_state, prod_state)
        end
    else
        prod_item = prod_result[1]
        prod_state = prod_result[2]
        return prod_item, (decomp_state, prod_state)
    end
end

 
##########################################
# Subword Iterator
##########################################

mutable struct SubwordIter
    bag::Bag
    subbag_iter::Union{Nothing,AllSubBagIter}
end

function SubwordIter(bag::Bag)
    return SubwordIter(bag, nothing)
end


function iterate(swi::SubwordIter)
    
    swi.subbag_iter = AllSubBagIter(swi.bag)
    sbi_result = iterate(swi.subbag_iter)
    if sbi_result == nothing
        return nothing
    end

    while true
        if sbi_result == nothing
            return nothing
        end

        sbi_item = sbi_result[1]
        sbi_state = sbi_result[2]

        if haskey(VOCAB_DICT, sbi_item)
            word_idx = 1
            return VOCAB_DICT[sbi_item][word_idx], (sbi_state, sbi_item, word_idx)
        else
            sbi_result = iterate(swi.subbag_iter, sbi_state)
        end
    end
end


function iterate(swi::SubwordIter, state)
    
    sbi_state = state[1]
    cur_bag = state[2]
    word_idx = state[3]

    word_idx += 1
    if word_idx > length(VOCAB_DICT[cur_bag])

        while true
            sbi_result = iterate(swi.subbag_iter, sbi_state)

            if sbi_result == nothing
                return nothing
            else
                sbi_item = sbi_result[1]
                sbi_state = sbi_result[2]
                
                if haskey(VOCAB_DICT, sbi_item)
                    word_idx = 1
                    return VOCAB_DICT[sbi_item][word_idx], (sbi_state, sbi_item, word_idx)
                else
                    continue
                end
            end
        end

    else
        return VOCAB_DICT[cur_bag][word_idx], (sbi_state, cur_bag, word_idx)
    end

end



