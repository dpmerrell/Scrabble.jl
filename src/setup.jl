


CHARACTERS = "abcdefghijklmnopqrstuvwxyz"
N_CHAR = length(CHARACTERS)
CHAR_TO_IDX = Dict([c => i for (i, c) in enumerate(CHARACTERS)])
BagType = Int
Bag = Vector{BagType}
VOCAB_DICT = Dict{Vector{Int},Vector{String}}()


function word_to_bag(word_str)

    bag = zeros(BagType, N_CHAR)
    for char in word_str
        bag[CHAR_TO_IDX[char]] += 1
    end
    return bag 
end

function bag_to_str(bag)
    chars = [repeat(CHARACTERS[i], bag[i]) for i=1:length(bag)]
    return string(chars...)
end

function build_vocab_dict(vocab_vec)
    
    d = Dict{Vector{Int},Vector{String}}()

    for word in vocab_vec
        bag = word_to_bag(word)
        if !haskey(d, bag)
            d[bag] = String[] 
        end
        push!(d[bag], word)
    end
    
    return d
end


function bag_complement(bag, subbag)
    return bag .- subbag
end


function bag_leq(bag1, bag2)
    s1 = sum(bag1)
    s2 = sum(bag2)
    if s1 != s2
        if s1 < s2
            return true
        else
            return false
        end
    end
    return bag1 >= bag2
end


function module_setup(charset=CHARACTERS, 
                      vocab_file=string(@__DIR__, "/collins_scrabble_2019.txt"))

    global CHARACTERS = charset
    global N_CHAR = length(CHARACTERS)
    global CHAR_TO_IDX = Dict([c => i for (i, c) in enumerate(CHARACTERS)])
    
    vocab_vec = open(vocab_file,"r") do f
        return readlines(f)
    end
    vocab_vec = [lowercase(word) for word in vocab_vec]
    global VOCAB_DICT = build_vocab_dict(vocab_vec)
    
    println(string("Loaded dictionary at ",vocab_file))

    return 
end

module_setup()


