using Core: GeneratedFunctionStub
using Base: Float64
include("StockParse.jl")

mutable struct IBPortfolioModel
    IBIndex::Index{InvestmentCompany}
    moneyAtDisposal::Float64
    currentPortfolio::OrderedDict{String,Int64}
    toBuy::OrderedDict{String,Int64}
    moneyLeft::Float64
    newPortfolio::OrderedDict{String,Int64}
    IBPortfolioModel(moneyAtDisposal::Float64 = 10000.0; path = nothing) = begin
        ibIndex = getIBIndex()
        currentPortfolio = (path == nothing) ? readCurrentPortfolio() : readCurrentPortfolio(path)
        toBuy, moneyLeft = calculateNumberOfStocksToBuy(moneyAtDisposal, ibIndex, currentPortfolio)
        newPortfolio = calculateNewPortfolio(currentPortfolio, toBuy)
        new(ibIndex, moneyAtDisposal, currentPortfolio, toBuy, moneyLeft, newPortfolio)
    end
end

function recalculatePortfolioModel!(model::IBPortfolioModel)
    model.toBuy, model.moneyLeft = calculateNumberOfStocksToBuy(model.moneyAtDisposal, model.IBIndex, model.currentPortfolio)
    model.newPortfolio = calculateNewPortfolio(model.currentPortfolio, model.toBuy)
    return nothing
end

function refreshIBIndex!(model::IBPortfolioModel)
    model.IBIndex = getIBIndex()
    recalculatePortfolioModel!(model)
end

function addToCurrentPortfolio!(model::IBPortfolioModel, tickerString::String, numberToAdd::Int64 = 1)
    if (numberToAdd + model.currentPortfolio[tickerString]) < 0
        throw(InvalidStateException("Minimum number of stocks in portfolio is 0, tried to add $(numberToAdd) while current is $(model.currentPortfolio[tickerString])", :error))
    end
    model.currentPortfolio[tickerString] += numberToAdd
    recalculatePortfolioModel!(model)
end

function setMoneyAtDisposal!(model::IBPortfolioModel, moneyAtDisposal::Float64)
    model.moneyAtDisposal = moneyAtDisposal
    recalculatePortfolioModel!(model)
end


