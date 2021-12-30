
export anagram_iter

function tabulate_decompositions(bag::Bag, decomp_memo=Dict{Bag,Vector{Bag}}(), 
                                           vocab_dict=VOCAB_DICT) 
    
    for subbag in AllSubBagIter(bag)
    
        # Check whether this subbag has any valid decompositions
        for a in AllSubBagIter(subbag)
            if haskey(vocab_dict, a)
                b = bag_complement(subbag, a)
                if haskey(decomp_memo, b) | all(b .== 0)
                    # push it onto the list of decompositions 
                    if haskey(decomp_memo, subbag)
                        push!(decomp_memo[subbag], a)
                    else
                        decomp_memo[subbag] = Bag[a]
                    end
                end
            end
        end
    end

    return decomp_memo
end


function anagram_iter(text::String)
    bag = word_to_bag(text)
    decomp_cache = tabulate_decompositions(bag)
    return AnagramIter(bag, decomp_cache)
end


