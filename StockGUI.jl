using GLMakie

#gui = Figure(resolution = (1800, 900))

scene, layout = layoutscene(resolution = (1600,1200))

buttonLayout = GridLayout()
scrollButtonLayout = GridLayout()
#buttonList = [Button(scene, label = "$i") for i = 1:10]
#for i = 1:5 upperRight[i,1] = buttonList[i] end

layout[1,2] = buttonLayout


buttonLayout[1,1] = upButton = Button(scene, label = "↑")
buttonLayout[2,1] = downButton = Button(scene, label = "↓")
buttonLayout[:,2] = scrollButtonLayout

numberOfVisibleOptions = 7
maxVisible = Node(numberOfVisibleOptions)
scrollButtonLock = Node(true)
on(downButton.clicks) do x
    if (scrollButtonLock[])
        scrollButtonLock[] = false
        delete!.(contents(scrollButtonLayout))
        maxVisible[] = minimum([maxVisible[] + 1, length(IBIndex)])
        for (i,j) in enumerate((maxVisible[]-(numberOfVisibleOptions-1)):maxVisible[])
            #upperRight[i,1] = buttonList[j] 
            scrollButtonLayout[i,1] = Button(scene, label = "$(IBIndex[j][1].ticker)") 
        end
        #layout[1,2] = upperRight
        println(x, ", ", maxVisible[])
        scrollButtonLock[] = true
    end
end
downButton.clicks[] = 0

xs = 1:0.2:10
ys = 0.5 .* sin.(xs)
barAx = Axis(scene, xticks = (1:length(IBIndex), [s.ticker for (s,w) in IBIndex]), xticklabelrotation = pi/2*0.7)
#xtickrotation!(90)

barplot!(barAx, 1:length(IBIndex), [100*w for (s,w) in IBIndex], color = [w for (s,w) in IBIndex])
layout[1,1] = barAx

rowsize!(layout, 1, Relative(0.5))
scene
