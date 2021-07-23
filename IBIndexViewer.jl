using GLMakie
using Colors
include("IBIndexModel.jl")

struct IBIndexViewer
    model::IBPortfolioModel
    fig::Figure
    plotGrid::GridLayout
    tableViewGrid::GridLayout
    tableLastViewable::Observable{Any}
    modelControllerGrid::GridLayout
    indexChanged::Observable{Any}
    portfolioChanged::Observable{Any}
    highlightedStock::Observable{Any}
    IBIndexViewer(model::IBPortfolioModel; numberOfVisibleOptions = 6, resolution = (1600, 1000), numberOfPlusMinusButtons::Int64 = 3) = begin
        fig = Figure(resolution = resolution)
        plotGrid, tableViewGrid, modelControllerGrid = [GridLayout() for i = 1:3]
        fig[1:2,1:4] = plotGrid
        fig[3:4,1:2] = tableViewGrid
        fig[3:4,3:4] = modelControllerGrid
        viewer = new(model, fig, plotGrid, tableViewGrid, Node(numberOfVisibleOptions), 
        modelControllerGrid, Node(true), Node(true), Node(model.IBIndex[1][1].ticker))
        initPlotGrid!(viewer)
        initTableViewGrid!(viewer, numberOfVisibleOptions)
        initModelControllerGrid!(viewer, numberOfPlusMinusButtons)
        colsize!(fig.layout,1,Relative(0.6))
        return viewer
    end
end

#Remove rand() later !!!
function initPlotGrid!(viewer::IBIndexViewer)
    IBIndex = viewer.model.IBIndex
    cmap = :grayyellow
    #viewer.plotGrid[1,1] = indexAx = Axis(viewer.fig, 
    #    xticks = (1:length(IBIndex), [s.ticker for (s,w) in IBIndex]), 
    #    xticklabelrotation = pi/2*0.7, title = "Current IB-Index")
    indexVals = lift(x-> [100*w for (s,w) in IBIndex], viewer.indexChanged)
    #barplot!(indexAx, indexVals, color = indexVals, colormap = cmap)
    viewer.plotGrid[1:2,1] = portfolioAx = Axis(viewer.fig, 
        xticks = (1:length(IBIndex), [s.ticker for (s,w) in IBIndex]), 
        xticklabelrotation = pi/2*0.7, title = "Current portfolio distribution")
    portfolioVals = lift((x,y)-> begin
                                totalPortfolioVal = sum([s.price * viewer.model.currentPortfolio[s.ticker] for (s,w) in viewer.model.IBIndex])
                                port = [100 * s.price * viewer.model.currentPortfolio[s.ticker]/totalPortfolioVal for (s,w) in viewer.model.IBIndex]
                                return port
                            end,
                    viewer.portfolioChanged, viewer.indexChanged)
    newPortfolioVals = lift((x,y)-> begin
                                    totalPortfolioVal = sum([s.price * viewer.model.newPortfolio[s.ticker] for (s,w) in viewer.model.IBIndex])
                                    port = [100 * s.price * viewer.model.newPortfolio[s.ticker]/totalPortfolioVal for (s,w) in viewer.model.IBIndex]
                                    return port
                                    end,
                        viewer.portfolioChanged, viewer.indexChanged)
    off = [-0.25, 0.0, 0.25]; barWidth = 0.22
    c = distinguishable_colors(2, [RGB(1.0,1.0,1.0), RGB(0.0,0.0,0.0)], dropseed = true)
    barplot!(portfolioAx, [i+off[1] for i = 1:length(IBIndex)], portfolioVals, color = RGB(0.7,0.3,0.3),# colormap = cmap,
    dodge = repeat([1], length(IBIndex)), width = barWidth, label = "Current portfolio")
    barplot!(portfolioAx, [i+off[2] for i = 1:length(IBIndex)], indexVals, color = RGB(0.3,0.3,0.7),#, colormap = cmap,
    dodge = repeat([2], length(IBIndex)), width = barWidth, label = "Index distribution")
    barplot!(portfolioAx, [i+off[3] for i = 1:length(IBIndex)], newPortfolioVals, color = RGB(0.9,0.6,0.0), 
    dodge = repeat([3], length(IBIndex)), width = barWidth, label = "Resulting portfolio")
    viewer.plotGrid[1:2,2] = Legend(viewer.fig, portfolioAx)
end

function getTableViewGridPositions(viewer::IBIndexViewer, numberOfVisibleOptions, vertical = true)
    positions = Dict{Symbol,Any}()
    if vertical
        positions[:header] = [1,2:5]
        positions[:stockButton] = [[viewer.tableLastViewable[]+2-i,3] for i = 1:numberOfVisibleOptions]
        positions[:ownedLabel] = [[viewer.tableLastViewable[]+2-i,3] for i = 1:numberOfVisibleOptions]
        positions[:toBuyLabel] = [[viewer.tableLastViewable[]+2-i,3] for i = 1:numberOfVisibleOptions]
        positions[:newPortLabel] = [[viewer.tableLastViewable[]+2-i,3] for i = 1:numberOfVisibleOptions]
    end
    return positions
end

function initTableViewGrid!(viewer::IBIndexViewer, numberOfVisibleOptions)
    tableViewGrid = viewer.tableViewGrid
    tablePos = getTableViewGridPositions(viewer, numberOfVisibleOptions, true)
    tableViewGrid[1,2:5] = [Label(viewer.fig, "Stock"), Label(viewer.fig, "Owned"), Label(viewer.fig, "To Buy"), Label(viewer.fig, "Result")]
    for i = 1:numberOfVisibleOptions
        stockLabel = lift(x -> "$(viewer.model.IBIndex[x+1-i][1].ticker)", viewer.tableLastViewable)
        tableViewGrid[viewer.tableLastViewable[]+2-i, 2] = stockButton = Button(viewer.fig, label = stockLabel)
        on(stockButton.clicks) do x
            viewer.highlightedStock[] =  viewer.model.IBIndex[viewer.tableLastViewable[]+1-i][1].ticker
        end
        ownedLabel = lift((x,y) -> "$(viewer.model.currentPortfolio[viewer.model.IBIndex[x+1-i][1].ticker])", viewer.tableLastViewable, viewer.portfolioChanged)
        tableViewGrid[viewer.tableLastViewable[]+2-i, 3] = Label(viewer.fig, ownedLabel)
        toBuyLabel = lift((x,y) -> "$(viewer.model.toBuy[viewer.model.IBIndex[x+1-i][1].ticker])", viewer.tableLastViewable, viewer.portfolioChanged)
        tableViewGrid[viewer.tableLastViewable[]+2-i, 4] = Label(viewer.fig, toBuyLabel)
        newPortLabel = lift((x,y) -> "$(viewer.model.newPortfolio[viewer.model.IBIndex[x+1-i][1].ticker])", viewer.tableLastViewable, viewer.portfolioChanged)
        tableViewGrid[viewer.tableLastViewable[]+2-i, 5] = Label(viewer.fig, newPortLabel)
    end
    tableViewGrid[2:end,1] = slider = Slider(viewer.fig, range = (length(viewer.model.IBIndex):(-1):numberOfVisibleOptions), horizontal = false, startvalue = numberOfVisibleOptions)
    prevSliderVal = Node(1); sliderLock = Node(true)
    on(slider.value) do x
        if sliderLock[]
            sliderLock[] = false
            if prevSliderVal[] != x
                prevSliderVal[] = x
                viewer.tableLastViewable[] = x
            end
            sliderLock[] = true
        end
    end
end

function initModelControllerGrid!(viewer::IBIndexViewer, numberOfPlusMinusButtons::Int64)
    grid = viewer.modelControllerGrid
    grid[1,1] = Label(viewer.fig, lift(x-> "$(x)", viewer.highlightedStock))
    grid[2,1] = Label(viewer.fig, lift((x,y)-> "Owned: $(viewer.model.currentPortfolio[x])", viewer.highlightedStock, viewer.portfolioChanged))
    grid[1, (2:(numberOfPlusMinusButtons+1))] = increaseOwnedButtons = [Button(viewer.fig, label = "+"^i) for i = 1:numberOfPlusMinusButtons]
    grid[2, (2:(numberOfPlusMinusButtons+1))] = decreaseOwnedButtons = [Button(viewer.fig, label = "- "^i) for i = 1:numberOfPlusMinusButtons]
    for (i, button) in enumerate([increaseOwnedButtons; decreaseOwnedButtons])
        on(button.clicks) do x
            toAdd = (i <= numberOfPlusMinusButtons) ? 10^(i-1) : -10^(i-numberOfPlusMinusButtons-1)
            toAdd = ((viewer.model.currentPortfolio[viewer.highlightedStock[]] + toAdd) >= 0) ? toAdd : -viewer.model.currentPortfolio[viewer.highlightedStock[]]
            addToCurrentPortfolio!(viewer.model, viewer.highlightedStock[], toAdd)
            viewer.portfolioChanged[] = true
        end
    end
    grid[3,1] = refreshButton = Button(viewer.fig, label = "Refresh IB-Index")
    on(refreshButton.clicks) do x viewer.indexChanged[] = true end
    capitalSlider = labelslider!(viewer.fig, "Capital:", -20000:500:20000)
    on(capitalSlider.slider.value) do x
        setMoneyAtDisposal!(viewer.model, Float64(x))
        viewer.portfolioChanged[] = true
    end
    grid[4,1:4] = capitalSlider.layout
end

view = IBIndexViewer(IBPortfolioModel())
view.fig