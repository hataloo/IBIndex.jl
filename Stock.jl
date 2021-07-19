import Base: setindex!, length, push!, show
using DataStructures
abstract type AbstractStock end

struct Stock <: AbstractStock
    name::String
    ticker::String
    price::Float64
end

struct InvestmentCompany <: AbstractStock
    name::String
    ticker::String
    price::Float64
    NAVRebatePremium::Float64
end

struct Index{T<:AbstractStock}
    stocks::Array{T,1}
    weights::Array{Float64,1}
    function Index{T}() where T<:AbstractStock 
        return new{T}(Array{T,1}(), Array{Float64,1}())
    end
end

function Base.push!(index::Index{T}, stockAndWeightToAdd::Tuple{T,Float64}) where T<:AbstractStock
    push!(index.stocks, stockAndWeightToAdd[1])
    push!(index.weights, stockAndWeightToAdd[2])
end

function Base.getindex(index::Index{T}, i::Int64) where T<:AbstractStock
    return index.stocks[i], index.weights[i]
end

function setindex!(index::Index{T}, stockAndWeight::Tuple{T, Float64}, i::Int) where T<:AbstractStock
    #=if (length(index.stocks) <= i || length(index.weights) <= i)
        newSize = maximum([2*length(index.stocks), 2*length(index.weights), i])
        resize!(index.stocks, newSize)
        resize!(index.weights, newSize)
    end=#
    if (i > length(index.stocks) + 1 || i > length(index.weights) + 1)
        throw(BoundsError("Cannot use setindex! on index with i > length(index.stocks) or i > length(index.weights), called setindex! with i = $i, length(index.stocks) = $(length(index.stocks)), length(index.weights) = $(length(index.weights))"))
    elseif (i == length(index.stocks) + 1 || i == length(index.weights) + 1)
        newSize = i+1
        resize!(index.stocks, newSize)
        resize!(index.weights, newSize)
    end
    index.stocks[i] = stockAndWeight[1]
    index.weights[i] = stockAndWeight[2]
end
function length(index::Index{T}) where T<:AbstractStock
    if (length(index.stocks) != length(index.weights))
        throw(InvalidStateException("Length of index.stocks and index.weights not equal, length(index.stocks) = $(length(index.stocks)) and length(index.weights) = $(length(index.weights))"))
    end
    return length(index.stocks)
end

function Base.show(io::IO, index::Index{T}) where T<:AbstractStock
    maxNameLength = maximum(length.([s.name for (s,w) in index])) 
    print(io, ["$(s.name),$(' '^(maxNameLength - length(s.name))) $(w)\n"  for (s,w) in index]...)
end

function Base.iterate(index::Index{T}, state = 1) where T<:AbstractStock
    if length(index) >= state 
        return (index[state], state+1)
    else
        return nothing
    end
end

function calculateNumberOfStocksToBuy(moneyAtDisposal::Float64, index::Index{T}, currentPortfolio::AbstractDict{String, Int}) where T<:AbstractStock
    toBuy = OrderedDict{String,Int}()
    totalMoney = moneyAtDisposal + sum([s.price * ((s.ticker in keys(currentPortfolio)) ? currentPortfolio[s.ticker] : 0) for (s,w) in index])
    for (stock, weight) in index
        currentNumber = (stock.ticker in keys(currentPortfolio)) ? currentPortfolio[stock.ticker] : 0
        toBuy[stock.name] = Int(round(totalMoney*weight/stock.price)) - currentNumber
    end
    moneyLeft = moneyAtDisposal - sum([s.price * toBuy[s.name] for (s,w) in index])
    return toBuy, moneyLeft
end