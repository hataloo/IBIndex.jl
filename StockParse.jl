using HTTP, JSON, CSV, DataStructures
include("Stock.jl")

function fetchFromIBIndex()
    #r = HTTP.get("https://ibindex.se")
    rWeights = HTTP.get("http://ibindex.se/ibi//index/getProductWeights.req")
    rProducts = HTTP.get("http://ibindex.se/ibi//index/getProducts.req")
    weightsInfo = JSON.parse(String(rWeights.body))
    productsInfo = JSON.parse(String(rProducts.body))
    #Replace improperly scanned chars with correct chars.
    for entry in [weightsInfo, productsInfo]
        for (_, dict) in enumerate(entry)
            dict["productName"] = replace(dict["productName"], "\xe4" => "ä")
            dict["productName"] = replace(dict["productName"], "\xf6" => "ö")
            dict["productName"] = replace(dict["productName"], "\xd6" => "Ö")
        end
    end
    return weightsInfo, productsInfo
end

function readCurrentPortfolio(path = "portfolio.csv")
    currentPortfolio = OrderedDict{String, Int64}()
    for row in CSV.File(path, header = false)
        #println(row)
        currentPortfolio[row[:Column1]] = row[:Column2]
    end
    return currentPortfolio
end

function buildIBIndex(productsInfo, weightsInfo)
    IBIndex = Index{InvestmentCompany}()
    #product and weight are sorted on different criteria, so need to check
    #for matching names and tickers.

    for product in productsInfo
        for weight in weightsInfo
            if (product["product"] == weight["product"] && product["productName"] == weight["productName"])
                ic = InvestmentCompany(product["productName"], product["product"], product["price"], product["netAssetValueCalculatedRebatePremium"])
                push!(IBIndex, (ic, weight["weight"]/100))
            end
        end
        if length(weightsInfo) == 0 #&& product["product"] in keys(currentPortfolio)
            println("IBIndex down? ", product["product"])
            ic = InvestmentCompany(product["productName"], product["product"], product["price"], product["netAssetValueCalculatedRebatePremium"])
            push!(IBIndex, (ic, 1/length(productsInfo)))
        end
    end
    return IBIndex
end

function getIBIndex()
    weightsInfo, productsInfo = fetchFromIBIndex()
    return buildIBIndex(productsInfo, weightsInfo)
end
#toBuy, moneyLeft = calculateNumberOfStocksToBuy(22500.0, IBIndex, currentPortfolio)

#newPortfolio = OrderedDict{String, Int64}([k => v + toBuy[k] for (k,v) in currentPortfolio])
function calculateNewPortfolio(currentPortfolio::AbstractDict{String,Int64}, toBuy::AbstractDict{String, Int64})
    return OrderedDict{String, Int64}([k => v + toBuy[k] for (k,v) in currentPortfolio])
end