
export jumble_iter

function jumble_iter(text::String)
    return SubwordIter(word_to_bag(text))
end


