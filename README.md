# IBIndex.jl
 
A graphical application that scrapes [IBIndex.se](https://ibindex.se/) for the current index distribution, reads the amount of stocks in portfolio.csv and calculates how much to buy/sell to best follow the index. 
Supports changing the amount of stocks in your portfolio and adding additional capital. 

<img src="/Figs/GUI-main.png" width="800">

Installing dependencies (tested on Julia 1.7.2):
```
using Pkg
dependencies = ["GLMakie", "DataStructures", "HTTP", "JSON", "CSV", "Statistics", "Colors"]
Pkg.add(dependencies)
```