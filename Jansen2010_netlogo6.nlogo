extensions [gis]

breed [actors actor]

patches-own [
  capacity ; production capacity of soil at cell
  technology ; efficiency in which aggriculture is practiced. More experienced lead to lower loss of soil
  attract ; attraction of settlements when agent like to move. Attraction depends how much more productive the location is expected to be.
  rain ; actual annual rainfall in that cell
  resource ; soil quality
  shortage ; total shortage of resources in settlement by all agents on patch
  surplus ; total surplus of resources in settlement by all agents on patch
  drawn? ; drawn to exchange with other settlements?
  nrp ; number of agents in a settlement
  land?
  house-color
  ]

actors-own [
  production ; food available after harvest, sharing, using storage and exchange
  stocks ; storage of food. list with food amounts for last 3 years
  estimate ; estimated harvest on a cell in the next year
  harvest ; actual harvest from cell
  nutritionneedremaining ; amount of food needed at different stages of storage, sharing and exchange
  duration ; the number of years an agent is living in this settlement
  debt ; virtual debt to others in sharing and exchange. Affect the reputation of an agent and a settlement
  buffer ; used for calculating whether agents have enough food to meet the buffer level
  isurplus ; surplus of food for individual agent
  grosssurplus]


globals [
  largest ; population size of largest settlement
  crain ; counter for rainfall scenario
  rain-data ; rainfall data
  listset ; help variable
  nrmigration ; number of agents who migrate to another settlement during a timestep
  aps ; average population size
  stress
  popsize
  resource_total
  production_total
  debtdist_total
]

to setup
  clear-all
  ;setup-world
  ; import rain data
  ifelse ( file-exists? "rain.txt" )
  [
    set rain-data []
    file-open "rain.txt"
    while [ not file-at-end? ]
    [
      set rain-data sentence rain-data (list file-read)
    ]
    file-close
  ]
  [ user-message "There is no rain.txt file in current directory!" ]
  let teller 0



  ;; setup the terrain
  ask patches [
    set shortage 0
    set surplus 0]

  ifelse novariabilitysoils
  [ask patches [
    set capacity 100
    set resource capacity]]
  [ask patches [set capacity random 200 set resource capacity] repeat 2 [ diffuse capacity 1 ]]

  ask patches [ set pcolor scale-color green capacity 50 180 set surplus 0]




  ; setup agents
  create-actors nractors [
    set size 0.5
    set shape "house"
    setxy int random-xcor int random-ycor
    set color yellow
    set stocks []
    set teller 0
    set debt 0
    while [teller <= yearsofstorage]
    [
      set stocks lput 50 stocks
      set teller teller + 1
    ]
    set production 85
    set duration 1
  ]
  ask patches [set nrp count actors-here]


  set crain 0
  reset-ticks
end

to setup-world
  ; Set up a virtual world using GIS raster base maps
  let basemap gis:load-dataset "C:/Users/user/NetLogo-Model/Land_raster.asc"  ; Loads the GIS data to temp variable basemap
  let world-wd gis:width-of basemap  ; Identifies the width of the GIS raster
  let world-ht gis:height-of basemap  ; Identifies the height of the GIS raster
  resize-world 0 ( world-wd - 1 ) 0 ( world-ht - 1 )  ; Sets the dimensions of the World window to fit the GIS raster
  gis:set-world-envelope gis:envelope-of basemap  ; Transforms the World window based on the GIS raster
  gis:set-sampling-method basemap "NEAREST_NEIGHBOR" ; makes sure resampling is by nearest neighbor

   ask patches [
    let myX pxcor  ; temp variable to record the X coordinate
    let myY pycor  ; temp variable to record the Y coordinate
    let myCoor ( list myX myY )  ; xy coordinates as a list for the next line
    set house-color gis:raster-sample basemap myCoor  ; Each patch querries the value from the raster at its location
  ]
  ; Identify land patches (house-color >= 0) (water patches have house-color -9999 in the raster)
  ask patches [
    ifelse house-color >= 0 [
      set land? true  ; patches with house-color >= 0 are land
    ][  ; closing the if statement
      set land? false  ; patches that have house-color < 0 (-9999 in this case) are water
      set pcolor blue   ; thus they are blue
    ]  ; closing the else statement
  ]  ; closing the "ask patches" statement

end



to go
  estimatefood
  calculaterain
  calculateyield
  harvestconsumption
  exchange
  move
  if popgrowth [popdynamics] ; one can chose a constant population size if popgrowth is false
  ask patches [set nrp count actors-here]
  tick

  if view = "capacity" [ask patches [set pcolor scale-color green capacity 20 180]]
  if view = "resource" [ask patches [ set pcolor scale-color green resource 10 140 ]]
   ifelse crain = 599 [set crain 0][set crain crain + 1] ; repeat sequence of raindata
end

to popdynamics
; defines whether agents are removed or added to the model. If a new agent is born it will be located on the patch of the "parent".
; Birth and death rates depend on the production level. Parent and new born agent will share the stock of resources from parent
let deathrate 0.02
let birthrate 0.03
let teller 0
let ys 1
  ask actors [
    if random-float 1.0 < deathrate * (2 - (production / 100.0)) [die]
  ]
  ask actors [
    if random-float 1.0 < birthrate * (production / 100.0 )
    [
      set teller 0
      set duration 1
      set debt 0
      while [teller <= yearsofstorage]
      [
        set stocks replace-item teller stocks (item teller stocks * 0.5)
        set debt debt * 0.5
        set teller teller + 1
      ]
      hatch 1
    ]
  ]
end

to estimatefood
; estimate the food available for the next timestep in a normal yea (precipitation).
let total 0
let ys 1
  ask actors [
    set total 0
    set ys yearsofstorage - 1
    while [ys > -1]
    [
      set total total + item ys stocks
      set ys ys - 1
    ]
    set estimate total + [technology] of patch-here * [resource] of patch-here * ([nrp] of patch-here) ^ par
  ]
end

to calculaterain
  ; calculates the precipitation at each cell
  ; it also calculates the soil quality due to recovery and degradation
  let teller 0
  let avg 0

  ask patches [
    ifelse climatevariabilityon [
      set rain 1.5 * (1 - exp ( - 0.137327 * (item crain rain-data + 8)))
      ][
      set rain 1]
    set rain rain * (1 + random-normal 0 settlevariation)
    set resource resource + ((resource / capacity) ^ degradationfactor) * recoverrate * resource * (1 - resource / capacity) - alpha * nrp
    if resource < 0 [set resource 0.0001]
  ]
  if view = "rain" [ask patches [set pcolor scale-color blue rain 0.5 2]]
end

to calculateyield
  ; First calculate the consequence of experience of the agents. Technology is high when agents have a lot of experience
  ; This leads to high production with the same level of soil quality
  ; Then calculate for each agent the harvest. There is some variation of individual harvest levels which is set to the same level as settlevariation
  ask patches [
    let totduration 0
    ask actors-here [ set totduration totduration + duration]
    ifelse totduration = 0 [set technology 1 / (1 + learningfactor)]
    [
      set technology (totduration / (totduration + learningfactor))
   ]
  ]
  ask actors
  [
    set harvest ([rain] of patch-here * [technology] of patch-here * [resource] of patch-here * nrp ^ par)*(1 + random-normal 0 settlevariation)
 ]
end

to harvestconsumption
  ; calculate the amount of resource agents can consumer when sharing and storing resources.
let ys 0
let sfood 0
let pool []
let distributed 0
let dummy 0
  ; define stocks and requirements
  ask actors
  [
    set ys yearsofstorage
    while [ys > 0]
    [
      set stocks replace-item ys stocks (efficiency * (item (ys - 1) stocks))
      set ys ys - 1
    ]
    set stocks replace-item 0 stocks harvest
    set nutritionneedremaining minnutritionneed
  ]

  ; there are three types of sharing. For each type we update the stocks
  if sharing = "independent" [
    ; define whether agents can receive basic needs?

    ask actors
    [
      set ys yearsofstorage - 1
      while [ys > -1]
      [
        ifelse ((item ys stocks) >= nutritionneedremaining)
        [
          set stocks replace-item ys stocks (item ys stocks - nutritionneedremaining)
          set nutritionneedremaining 0
        ]
        [
          set nutritionneedremaining (nutritionneedremaining - item ys stocks)
          set stocks replace-item ys stocks 0
        ]
        set ys ys - 1
      ]
    ]
  ]
  let locprod 0
  if sharing = "pooling" [
    let dummycstore 0
    let dummycharvest 0

    ask patches [
      if count actors-here > 0
      [
        set pool []
        set ys 0
        set sfood 0
        while [ys <= yearsofstorage] ; calculate the total pool of resources, taking into account the year from which the resource is coming
        [
          set pool lput 0 pool
          set ys ys + 1
        ]
        set dummycstore 0
        set dummycharvest 0
        ask actors-here [
          set ys 0
          set locprod 0
          while [ys <= yearsofstorage]
          [
            set pool replace-item ys pool (item ys pool + item ys stocks)
            ifelse ys = 0 [set dummycharvest dummycharvest + item ys stocks][set dummycstore dummycstore + item ys stocks]
            set sfood sfood + item ys stocks
            set locprod locprod + item ys stocks
            set ys ys + 1
          ]
        ]
        set sfood sfood / count actors-here  ; stock of food per agent in patch

        ; if there is enough food then everybody is satisfied, otherwise, everybody has the same shortage
        ask actors-here [ifelse (sfood >= nutritionneedremaining) [set nutritionneedremaining 0][set nutritionneedremaining nutritionneedremaining - sfood]]

        set ys 0
        while [ys <= yearsofstorage]
        [
          set pool replace-item ys pool (item ys pool / count actors-here)
          set ys ys + 1
        ]
        ask actors-here [
          set distributed minnutritionneed
          set ys yearsofstorage - 1
          while [ys > -1]
          [
            ifelse distributed > 0
            [
              ifelse (distributed - item ys pool) < 0
              [
                set stocks replace-item ys stocks (item ys pool - distributed)
                set distributed 0
              ][
                set stocks replace-item ys stocks 0
                set distributed distributed - item ys pool
             ]
            ][
              set stocks replace-item ys stocks (item ys pool)
            ]
            set ys ys - 1
          ]
        ]
      ]
    ]
  ]
  if sharing = "restricted sharing" [
    set locprod 0

    ; first individually harvest and use stocks
    ask actors
    [
      set isurplus 0
      set grosssurplus 0
      set ys yearsofstorage - 1
      while [ys > -1]
      [
        set grosssurplus grosssurplus + item ys stocks
        ifelse ((item ys stocks) >= nutritionneedremaining)
        [
          set stocks replace-item ys stocks (item ys stocks - nutritionneedremaining)
          set nutritionneedremaining 0
          set isurplus isurplus + item ys stocks
        ]
        [
          set nutritionneedremaining (nutritionneedremaining - item ys stocks)
          set stocks replace-item ys stocks 0
          set isurplus isurplus + item ys stocks
        ]
        set ys ys - 1
      ]
      ifelse isurplus > bufferlevel [set isurplus isurplus - bufferlevel] [set isurplus 0]
    ]
    ask patches [
      set shortage 0
      set surplus 0
      ask actors-here [
        set surplus surplus + isurplus
        set shortage shortage + nutritionneedremaining
      ]
      ifelse surplus > shortage [
        ask actors-here [
          if isurplus > 0 [
            set dummy isurplus * (shortage / surplus)  ; update stocks
            set ys yearsofstorage - 1
            while [ys > -1]
            [
              ifelse item ys stocks > dummy
              [
                set stocks replace-item ys stocks (item ys stocks - dummy)
                set dummy 0
              ][
                set dummy dummy - item ys stocks
                set stocks replace-item ys stocks 0
              ]
              set ys ys - 1
            ]
          ]
          if nutritionneedremaining > 0 [set nutritionneedremaining 0]
        ]
      ][
        ask actors-here [
          if isurplus > 0
          [
            set dummy isurplus
            set ys yearsofstorage - 1
            while [ys > -1]
            [
              ifelse item ys stocks > dummy
              [
                set stocks replace-item ys stocks (item ys stocks - dummy)
                set dummy 0
              ][
                set dummy dummy - item ys stocks
                set stocks replace-item ys stocks 0
              ]
              set ys ys - 1
            ]
          ]
          if nutritionneedremaining > 0 [
            set nutritionneedremaining nutritionneedremaining * (1 - (surplus / shortage))
          ]
        ]
      ]
    ]
    let sumfood 0
    let sumprod 0
    ask actors [
      set sumfood sumfood + minnutritionneed - nutritionneedremaining
      ifelse grosssurplus <= minnutritionneed [
        set sumprod sumprod + grosssurplus
      ][
        set sumprod sumprod + minnutritionneed
      ]
    ]
  ]
  ask actors [if nutritionneedremaining < 0 [set nutritionneedremaining 0]]

end

to exchange
  ; procedure to calculate the exchange between agents and settlements
let rad 0
let teller 0
  ask patches [
    if view = "surplus" [set pcolor white]
    set shortage 0
    set surplus 0
    if nrp > 0
    [
      ask actors-here
      [
        set shortage shortage + nutritionneedremaining ; calculate the shorage of the settlement
        set buffer 0
        set teller 0
        while [teller < yearsofstorage]
        [
          if buffer >= bufferlevel [set surplus surplus + item teller stocks ] ; calculate whether the agent has enough food to use as a buffer
          if buffer < bufferlevel [
            ifelse (buffer + item teller stocks) > bufferlevel
            [
              set buffer bufferlevel
              set surplus surplus + (buffer + item teller stocks - bufferlevel)
            ][
              set buffer buffer + item teller stocks
            ]
          ]

          set teller teller + 1
        ]
      ]

      if view = "surplus" [if (shortage > 0) [set pcolor red] if (surplus > 0) [set pcolor green]]
     ]
    ]

  if exchangebs [
    let loss 0
    ask patches [set drawn? false]   ; settlements can be drawn once to do exchange
    let others 0
    let fractiono 0
    let shortagehelp 0
    let avgdebt 0
    ask patches [
      if ((shortage > 0) and (not drawn?)) [
        set drawn? true
        ask actors-here [set avgdebt avgdebt + debt]
        set avgdebt avgdebt / count actors-here
        if (avgdebt) < maxdebt [
        set others one-of patches with [surplus > 0]
        if others != nobody [
          set loss 0.02 * distance one-of actors-here
            ifelse (([surplus] of others * (1 + loss) - shortage) >= 0) [
              ask actors-here
              [
                set nutritionneedremaining 0
                set debt debt + shortage / count actors-here
              ]
              set fractiono shortage / (([surplus] of others) * (1 + loss))
              ask actors-on others
              [
                set teller 0
                while [teller <= yearsofstorage]
                [
                  set stocks replace-item teller stocks (item teller stocks * (1 - fractiono))
                  set teller teller + 1]
                set debt debt - shortage / count actors-on others
              ]
              let helpshortage shortage ; temporary value
              ask others [set surplus surplus - helpshortage]
              set shortage 0
            ]
            [
              set shortagehelp shortage
              ask actors-here
              [
                set nutritionneedremaining (shortagehelp - [surplus] of others) / ((1 + loss) * count actors-here)
                set debt debt + [surplus] of others / ((1 + loss) * count actors-here)
              ]
              set shortage shortage - [surplus] of others / (1 + loss)
              ask actors-on others
              [
                set teller 0
                while [teller <= yearsofstorage]
                [
                  set stocks replace-item teller stocks 0
                  set teller teller + 1
                ]
                set debt debt - [surplus] of others / (count actors-on others)
              ]
              ask others [set surplus 0]
            ]
]
        ]
      ]
    ]
  ]
  ask actors [ set production minnutritionneed - nutritionneedremaining]
end

to move
  let expprod 0
  let axcor 0
  let aycor 0
  let txcor 0
  let tycor 0
  let attractmax 0
  let move? true
  let expresource 0
  let teller 0
  let total 0
  let ys 0

  set nrmigration 0

  ask actors [
    set axcor [pxcor] of patch-here
    set aycor [pycor] of patch-here

    set total 0
    set ys yearsofstorage - 1
    while [ys > -1]
    [
      set total total + item ys stocks
      set ys ys - 1
    ]
    ifelse total <= bufferlevel * buffermove [set move? true][set move? false]
    if not move? [ifelse nutritionneedremaining > 0 [set move? true][set move? false]]
    if move? [
      set expresource [resource] of patch-here + recoverrate * (([resource] of patch-here / [capacity] of patch-here) ^ degradationfactor) * [resource] of patch-here * (1 - [resource] of patch-here / [capacity] of patch-here) - alpha * count actors-here
      if expresource < 0 [set expresource 0.0001]
      set attractmax threshold * ( ((count actors-here) ^ par) * expresource * [technology] of patch-here)
      set txcor axcor
      set tycor aycor
      ask patches in-radius radius [     ; find the most attractive patch of expected resources
        set expresource resource + recoverrate * resource * ((resource / capacity) ^ degradationfactor) * (1 - resource / capacity) - alpha * (count actors-here + 1)
        if expresource < 0 [set expresource 0.0001]
         ifelse attractmax > (technology * expresource) [set expprod 0]
        [
          set expprod (technology * expresource * ((1 + count actors-here) ^ par))
        ]
        ifelse expprod > attractmax [set attract expprod][set attract 0]
      ]

      let totattract 0 ; agents are most likely to go to the settlement which is most attractive, but there is some noise. This is a roulete wheel drawing of the new location
      ask patches in-radius radius [ set totattract totattract + attract]
      let drawnattract random-float totattract
      set totattract 0
      let found 0
      ask patches in-radius radius [
        set totattract totattract + attract
        if found = 0 and drawnattract < totattract [set found 1 set txcor pxcor set tycor pycor]
      ]
      set xcor txcor
      set ycor tycor
      if (xcor != axcor) or (ycor != aycor) [
        set nrmigration nrmigration + 1
        set duration 1
        set teller 0
        while [teller <= yearsofstorage]
        [
          set stocks replace-item teller stocks 0
          set teller teller + 1
        ]
      ]
    ]
    set duration duration + 1
  ]
end

@#$#@#$#@
GRAPHICS-WINDOW
200
9
518
328
-1
-1
10.0
1
2
1
1
1
0
1
1
1
0
30
0
30
0
0
1
years
30.0

BUTTON
524
10
588
44
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
591
10
655
44
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
4
9
177
42
nractors
nractors
0
2500
674.0
1
1
NIL
HORIZONTAL

SLIDER
6
50
179
83
radius
radius
1
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
6
95
179
128
bufferlevel
bufferlevel
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
5
135
178
168
recoverrate
recoverrate
0
1
0.085
0.0001
1
NIL
HORIZONTAL

SLIDER
5
173
178
206
alpha
alpha
0
1
0.54
0.01
1
NIL
HORIZONTAL

SLIDER
4
215
177
248
yearsofstorage
yearsofstorage
0
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
2
255
175
288
learningfactor
learningfactor
0
2
1.02
0.01
1
NIL
HORIZONTAL

SLIDER
6
295
179
328
buffermove
buffermove
0
1
0.51
0.01
1
NIL
HORIZONTAL

SLIDER
5
333
178
366
settlevariation
settlevariation
0
0.2
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
4
370
177
403
degradationfactor
degradationfactor
0
2
0.99
0.01
1
NIL
HORIZONTAL

SLIDER
11
411
184
444
maxdebt
maxdebt
0
1000
109.0
1
1
NIL
HORIZONTAL

SLIDER
9
453
182
486
efficiency
efficiency
0
1
0.75
0.01
1
NIL
HORIZONTAL

SLIDER
8
493
181
526
threshold
threshold
1
2
1.5
0.01
1
NIL
HORIZONTAL

SLIDER
6
535
179
568
minnutritionneed
minnutritionneed
0
100
86.0
1
1
NIL
HORIZONTAL

SLIDER
6
578
179
611
par
par
-1
1
0.2
0.01
1
NIL
HORIZONTAL

SWITCH
533
61
683
94
novariabilitysoils
novariabilitysoils
0
1
-1000

SWITCH
531
105
696
138
climatevariabilityon
climatevariabilityon
1
1
-1000

SWITCH
532
146
652
179
popgrowth
popgrowth
0
1
-1000

SWITCH
530
186
657
219
exchangebs
exchangebs
0
1
-1000

CHOOSER
692
15
831
60
view
view
"surplus" "resource" "capacity" "rain" "house-color"
1

CHOOSER
840
15
989
60
sharing
sharing
"independent" "pooling" "restricted sharing"
1

PLOT
720
116
920
266
rainfall
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (item crain rain-data)"

PLOT
720
270
920
420
Aggregation
NIL
NIL
0.0
30.0
0.0
10.0
true
false
"set popsize []\n" "set popsize [0]\n ask patches [\n    if count actors-here > 0 [\n    set popsize lput count actors-here popsize]\n  ]\n  set-histogram-num-bars 25"
PENS
"default" 1.0 1 -16777216 true "" "histogram popsize"

PLOT
718
422
918
572
AveragePopulationSize
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"set aps 0\n" "ask patches [if count actors-here > 0 [ set aps aps + 1]]\nif aps > 0 [set aps count actors / aps ]"
PENS
"default" 1.0 0 -16777216 true "" "plot aps"

PLOT
699
580
1009
861
Population
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count actors"

PLOT
923
270
1123
420
Migration
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot nrmigration"

PLOT
922
424
1122
574
stress
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"set stress 0\n" "ask actors [if production < 0.5 * minnutritionneed [set stress stress + 1]]\nif count actors > 0 [set stress stress / count actors]"
PENS
"default" 1.0 0 -16777216 true "" "plot stress"

PLOT
1125
113
1325
263
Production
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"set production_total 0" "set production_total 0\nask actors [set production_total production_total + production]\n"
PENS
"default" 1.0 0 -16777216 true "" "ifelse count actors > 0 [plot production_total / count actors][plot 0]"

PLOT
1129
266
1329
416
largest
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"set listset[]\n\n" "set listset [0]\nask patches [set listset lput count actors-here listset]\nset largest max listset"
PENS
"default" 1.0 0 -16777216 true "" "plot largest"

PLOT
1128
422
1328
572
debtdist
NIL
NIL
-100.0
200.0
0.0
10.0
true
false
"set debtdist_total []" "set debtdist_total [0]\nask actors [set debtdist_total lput debt debtdist_total]\nset-histogram-num-bars 25"
PENS
"default" 1.0 1 -16777216 true "set-histogram-num-bars 25" "histogram debtdist_total"

PLOT
923
117
1123
267
Resource
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"set resource_total 0 ; average soil quality among patches" "set resource_total 0 \nask patches [set resource_total resource + resource_total]"
PENS
"default" 1.0 0 -16777216 true "" "plot resource_total"

MONITOR
531
231
614
276
NIL
count actors
17
1
11

@#$#@#$#@
## MODEL

The purpose of this model is to help understand how prehistoric societies adapted to the prehistoric American southwest landscape. In the American southwest there is a high degree of environmental variability and uncertainty, like in other arid and semiarid regions. With the model you can explore how various assumptions concerning social processes affect the level of aggregation, population size and distribution of settlements.

nragents = number of agents at start of the simulation
radius = definition of neighborhood with whom to exchange or move to
bufferlevel = amount of resources the agent likes to keep in stock
recoveryrate = recovery rate of soil quality
alpha = degradation rate of soil from agents on the patch who use the soil
yearsofstorage = the number of years food surplus is kept in storage
learningfactor = the learning factor in the formulation of deriving experience
buffermove = if buffer is buffermove * bufferlevel agents will leave the location
settlevariation = variation of rainfall and harvest among agents and patches
degradationfactor = factor that affect the shape of resource dynamics, with positive values resource dynamics become hysteresis or irreversible
maxdebt = maximum debt agents tollerate if asked for exchange
efficiency = fraction of resources in stock surviving each year
threshold = how much better need to new location be compared to existing location before one moves?
minnutritientneed = amount of resources agents need per time step

novariabilitysoils = one can have heterogeienty of carrying capacity or no heterogeneity
climatevariabilityon = one can have climate variability or assume constant amount of rain
popgrowth = one can assume a constant population level, or population dynamics
exchangebs = one can assume exchange between settlements or turn this off
sharing = type of sharing one assumes: no sharing (independent), pooling or restricted sharing
par = parameter of production function


## CREDITS AND REFERENCES

The model is developed by Marco A. Janssen, Arizona State University, January 2010. Copyright (C) 2010 M.A. Janssen

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; either version 2 of the License, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
