# IBIndex.jl
 
A graphical application that scrapes [IBIndex.se](https://ibindex.se/) for the current index distribution, reads the amount of stocks in portfolio.csv and calculates how much to buy/sell to best follow the index. 
Supports changing the amount of stocks in your portfolio and adding additional capital. 

<img src="/Figs/GUI-main.png" width="800">

## What is [IBIndex.se](https://ibindex.se/)?

IB-index follows Swedish investment companies on the Stockholm Stock Exchange. IB-index gives the companies an equal base weight which is often preferable compared to a market weighted index. The weighting is adjusted according to the Net Asset Value discount or premium, a discount gives a company an increased weight in the index whereas a premium gives a reduced weight.

What is the rationale behind that?

As an example, if investment company A has a market cap of 100 million SEK and own stocks of the publicly traded company B for a value of 120 million SEK you would pay a lower price for the stock of company B by buying stocks of company A. The theory is that investment companies traded at a discount will outperform investment companies valued at a premium and that investment companies will outperform the market as a whole.

<img src="https://github.com/hataloo/IB-Index/blob/master/IBIndexShowcase/startpage.png" width="450">
<img src="https://github.com/hataloo/IB-Index/blob/master/IBIndexShowcase/valuation.png" width="500">


## Installing dependencies (tested on Julia 1.7.2):
```
using Pkg
dependencies = ["GLMakie", "DataStructures", "HTTP", "JSON", "CSV", "Statistics", "Colors"]
Pkg.add(dependencies)
```