using GLMakie

include("IBIndexModel.jl")

struct IBIndexViewer
    model::IBPortfolioModel
    fig::Figure
    plotGrid::GridLayout
    tableViewGrid::GridLayout
    modelControllerGrid::GridLayout
    IBIndexViewer(model::IBPortfolioModel) = begin
        fig = Figure(resolution = (1200,1000))
        plotGrid, tableViewGrid, modelControllerGrid = [GridLayout() for i = 1:3]
        fig[1:4,1:2] = plotGrid
        fig[1:2,3:4] = tableViewGrid
        fig[3:4,3:4] = modelControllerGrid
        new(model, fig, plotGrid, tableViewGrid, modelControllerGrid)
    end
end

function initPlotGrid!()