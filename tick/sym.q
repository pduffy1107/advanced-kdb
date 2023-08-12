// Define the Trade, Quote and Aggregation Tables
trade:([] time:"n"$(); sym:`$(); px:"f"$(); sz:"h"$());

quote:([] time:"n"$(); sym:`$(); bid:"f"$(); ask: "f"$(); bsize:"j"$(); asize:"j"$());

agg:([] time:"n"$(); sym:`$(); minPx:"f"$(); maxPx:"f"$(); minBid:"f"$(); maxBid:"f"$(); minAsk:"f"$(); maxAsk:"f"$(); volume: "j"$(); ToB:"f"$());

