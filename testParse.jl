using CSV: String
using Base: String, Float64
using Cascadia, Gumbo, HTTP, JSON, CSV, DataStructures

r = HTTP.get("https://ibindex.se")
rWeights = HTTP.get("http://ibindex.se/ibi//index/getProductWeights.req")
rProducts = HTTP.get("http://ibindex.se/ibi//index/getProducts.req")
j = JSON.parse(String(rWeights.body))
j2 = JSON.parse(String(rProducts.body))
for k in [j,j2]
    for (i,e) in enumerate(k)
        e["productName"] = replace(e["productName"], "\xe4" => "ä")
        e["productName"] = replace(e["productName"], "\xf6" => "ö")
        e["productName"] = replace(e["productName"], "\xd6" => "Ö")
        #println("$i : ", e)
    end
end
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

struct Index 
    stocks::Array{AbstractStock,1}
    weights::Array{AbstractStock,1}
end

struct IB
    name::String
    ticker::String
    price::Float64
    NAVRebatePremium::Float64
    weight::Float64
    rawWeightData::Dict{Symbol, Any}
    rawProductData::Dict{Symbol, Any}
end

function initIB(weightData::Dict{String, Any}, productData::Dict{String, Any})
    w = Dict{Symbol, Any}([ Symbol(key) => value for (key, value) in weightData])
    p = Dict{Symbol, Any}([ Symbol(key) => value for (key, value) in productData])
    if (w[:productName] != p[:productName])
       throw(ArgumentError("Names do not match, weightData has entry productName = $(w[:productName]) while productData has entry productName = $(p[:productName])")) 
    end
    if (w[:product] != p[:product])
        throw(ArgumentError("Products do not match, weightData has entry product = $(w[:product]) while productData has entry product = $(p[:product])")) 
     end
    IB(w[:productName],w[:product], p[:price], p[:netAssetValueCalculatedRebatePremium]/100, w[:weight]/100, w, p,)
end

investmentbolag = Dict{Symbol,IB}()
investmentbolag2 = Array{IB,1}(undef, length(j))

added = 0
for product in j2
    for weight in j
        global added
        if (product["product"] == weight["product"] && product["productName"] == weight["productName"])
            added += 1
            investmentbolag[Symbol(replace(product["product"], " " => ""))] = initIB(weight, product)
            investmentbolag2[added] = initIB(weight, product)
        end
    end
end

currentPortfolio = Dict{String, Int}()
for row in CSV.File("innehav.csv", header = false)
    #println(row)
    currentPortfolio[row[:Column1]] = row[:Column2]
end

weights = Dict{String, Float64}([x.ticker => x.weight for x in investmentbolag2])

function calculateNumberOfStocksToBuy(moneyAtDisposal::Float64, stocks::Array{IB,1}, weights::Dict{String,Float64},currentPortfolio::Dict{String, Int})
    toBuy = Dict{String,Int}()
    #toBuy = Array{Int,1}(undef, length(stocks)) 
    totalMoney = moneyAtDisposal + sum([x.price *currentPortfolio[x.ticker] for x in stocks])
    for (i,stock) in enumerate(stocks)
        weight = (stock.ticker in keys(currentPortfolio)) ? weights[stock.ticker] : 0
        currentNumber = (stock.ticker in keys(currentPortfolio)) ? currentPortfolio[stock.ticker] : 0
        toBuy[stock.name] = Int(round(totalMoney * weight/stock.price)) - currentNumber
    end
    moneyLeft = moneyAtDisposal - sum([x.price * toBuy[x.name] for x in stocks])
    return toBuy, moneyLeft
end

toBuy, moneyLeft = calculateNumberOfStocksToBuy(30000.0, investmentbolag2, weights, currentPortfolio)

toBuySorted = sort(collect(toBuy), by = x -> x[1])