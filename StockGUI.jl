using GLMakie

#gui = Figure(resolution = (1800, 900))

scene, layout = layoutscene(resolution = (1600,1200))

buttonLayout = GridLayout()
scrollButtonLayout = GridLayout()
#buttonList = [Button(scene, label = "$i") for i = 1:10]
#for i = 1:5 upperRight[i,1] = buttonList[i] end

layout[1:1,2] = buttonLayout



numberOfVisibleOptions = 5
for i = 1:numberOfVisibleOptions
    stock, weight = IBIndex[i]
    buttonLayout[i+1,2] = Button(scene, label = "$(stock.ticker)")
    buttonLayout[i+1,3] = Label(scene, "$(currentPortfolio[stock.ticker])")
    buttonLayout[i+1,4] = Label(scene, "$(toBuy[stock.ticker])")
    buttonLayout[i+1,5] = Label(scene, "$(newPortfolio[stock.ticker])")
end
#buttonLayout[2:(numberOfVisibleOptions+1),2:(1 + size(scrollButtonLayout)[2])] = scrollButtonLayout
buttonLayout[div(numberOfVisibleOptions,2)+1,1] = upButton = Button(scene, label = "↑")
buttonLayout[div(numberOfVisibleOptions,2)+2,1] = downButton = Button(scene, label = "↓")
buttonLayout[1,2:5] = [Label(scene, "Stock"), Label(scene, "Owned"), Label(scene, "To Buy"), Label(scene, "Result")]
#rowsize!(buttonLayout,2, Relative(numberOfVisibleOptions/(numberOfVisibleOptions+1)/2))
#rowsize!(buttonLayout,3, Relative(numberOfVisibleOptions/(numberOfVisibleOptions+1)/2))


firstVisible = Node(1)
scrollButtonVisible = Node([1,numberOfVisibleOptions])
scrollButtonLock = Node(true)
function updateScrollList()
    for (i,j) in enumerate(scrollButtonVisible[][1]:scrollButtonVisible[][2])
        button = content(buttonLayout[i+1,2])
        button.label = "$(IBIndex[j][1].ticker)"
        ownedLabel = content(buttonLayout[i+1,3])
        ownedLabel.text = "$(currentPortfolio[IBIndex[j][1].ticker])"
        toBuyLabel = content(buttonLayout[i+1,3])
        toBuyLabel.text = "$(toBuy[IBIndex[j][1].ticker])"
        resultLabel = content(buttonLayout[i+1,3])
        resultLabel.text = "$(newPortfolio[IBIndex[j][1].ticker])"
    end
end

on(downButton.clicks) do x
    if (scrollButtonLock[])
        scrollButtonLock[] = false
        if scrollButtonVisible[][2] < length(IBIndex)
            scrollButtonVisible[] .+= 1
            updateScrollList()
        end
        println(x, ", ", scrollButtonVisible[])
        scrollButtonLock[] = true
    end
end
on(upButton.clicks) do x
    if (scrollButtonLock[])
        scrollButtonLock[] = false
        if scrollButtonVisible[][1] > 1
            scrollButtonVisible[] .-= 1
            updateScrollList()
        end
        println(x, ", ", scrollButtonVisible[])
        scrollButtonLock[] = true
    end
end
buttonLayout[:,1] = slider = Slider(scene, range = (length(IBIndex)):(-1):(numberOfVisibleOptions), horizontal = false, startvalue = (1))
prevSliderVal = slider.value[]
sliderLock = Node(true)
on(slider.value) do x
    if sliderLock[]
        println(x)
        global prevSliderVal
        sliderLock[] = false
        if prevSliderVal[] != x[]
            scrollButtonVisible[] = [x[]-numberOfVisibleOptions+1,x[]]
            updateScrollList()
            prevSliderVal = slider.value[]
        end
        
        sliderLock[] = true
    end
end
#upButton.clicks[] = 0
#downButton.clicks[] = 0


indexBarAx = Axis(scene, xticks = (1:length(IBIndex), [s.ticker for (s,w) in IBIndex]), xticklabelrotation = pi/2*0.7, title = "Current IB-Index")
#xtickrotation!(90)
barplot!(indexBarAx, 1:length(IBIndex), [100*w for (s,w) in IBIndex], color = 1:length(IBIndex))
layout[1,1] = indexBarAx

portfolioBarAx = Axis(scene, xticks = (1:length(IBIndex), [s.ticker for (s,w) in IBIndex]), xticklabelrotation = pi/2*0.7, title = "Current Portfolio distribution")

totalPortfolioValue = sum([s.price * currentPortfolio[s.ticker] for (s,w) in IBIndex])
barplot!(portfolioBarAx, 1:length(currentPortfolio), [100*s.price*currentPortfolio[s.ticker]/totalPortfolioValue for (s,w) in IBIndex], color = 1:length(IBIndex))
layout[2,1] = portfolioBarAx

rowsize!(layout, 1, Relative(0.5))
scene
