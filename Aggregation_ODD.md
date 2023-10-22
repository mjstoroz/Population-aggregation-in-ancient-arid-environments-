# Model Description

@ Marco Janssen

This is a model description of an original model discussed in publication Janssen (2010). The model description follows the ODD protocol for describing individual- and agent-based models (Grimm et al. 2006) and consists of seven elements. The first three elements provide an overview, the fourth element explains general concepts underlying the model’s design, and the remaining three elements provide details. Additionally, details of the software
implementation are presented.

## 1. Purpose

The purpose of this model is to help understand how prehistoric societies adapted to the prehistoric American southwest landscape. In the American southwest there is a high degree of environmental variability and uncertainty, like in other arid and semiarid regions. With the model we like to explore how various assumptions concerning social processes affect the level of aggregation, population size and distribution of settlements.

## 2. State variables and scales

The landscape consists of NxN cells. We assume N to be 20, so the landscape consists of 400 cells. No specific area is simulated, but to calibrate certain parameter values, such as travel costs, we assume that each cell is 10 x 10 km. To avoid edge effects in this artificial closed system we represent space as a – donut shape –– torus.

An agent represents a number of individuals who act as a decision making unit. This is probably an extended family household or a small number of households. We assume that each agent represents the same number of individuals. In the basic model agents differ only in location, storage available, and debt (net amount of resource derived from exchange) but not in the decision-making rules.

The model proceeds in annual time steps, and we make simulations for 10,000 years to explore long term effects.

## 3. Process overview and scheduling

Every time step agents harvest resources on the cell they are occupying. They may share this cell with other agents, and such a cell represents a settlement. After all agents have harvested resources and take into account the stored surplus from previous years, they will check whether this will satisfy their demand. All agents will then consider to share resources or receive from sharing, within the settlement. When there are still agents within a settlement not having enough resources to meet the demand, settlements may receive resources from another settlement (exchange). This can only happen when there is a settlement with a surplus within the neighborhood. If after all this agents still are not able to make ends meet, they consider to migrate to another settlement, if there is another option available that lead to an improvement.

The population size affects the soil quality (degradation), and continuous occupation of a settlement lead to experience and higher productivity of the resource with the same labor input and soil quality. Rainfall variations affect the actual productivity of the land, together with soil quality, labor input and experience. Population levels are affected by migration, as well as natural population change by birth and death of agents. Lower amount of resources reduces birth rate and increases death rate.

![Figure 1](Fig1.png)

_Figure 1: Scheme of the main processes in the model. <> are decision moments of the agents._

## 4. Design concepts

**Adaptation:** Agents adapt to the landscape by storing resources, or move to other locations. Longer duration of agents in a settlement increase the local knowledge and the relative productivity of the land.

**Fitness:** Agents need to meet a minimum amount of resources to be satisfied. If this is not possible they may move to another location, and have higher probability to die. Prediction. Agents estimate the expected production of another location before deciding to move to that location.

**Interaction:** Agents interact indirectly by using the environment of a cell, by depleting the soil. Within a settlement they interact directly by sharing experience (production level) and by sharing resources. Between settlements there is exchange of resources.

**Stochasticity:** There is rainfall variability between the years. Besides the annual rainfall trend for the region, cells may differ due to spatial of rainfall variability. Furthermore, when two agents harvest resources from the same patch, there is some noise added to the actual amount harvested. The order in which agents are updated is random. This may have an effect on the exchange of resources between settlements, since settlements who are drawn first have an advantage.

**Collectives:** A settlement is defined by the agents who occupy one cells

## 5. Initialization

The agents are randomly allocated to cells on the landscape. Initially each agent receives a value of 50 units in storage for each of the 3 years resources are kept in stock. The length of time in a settlement is set to one for each agent in the current settlement. The debt that each agent has is set to zero at the initialization of the model.

## 6. Input

### 6.1 Rainfall data

The rainfall signal used here is the annual value of the Palmer Drought Severity Index (PDSI). The model uses actual historical sequences of reconstructed PDSI for the period 900 – 1500 for a typical location in the US southwest[^1] (Figure 2). For our simulations of 10,000 years, we use a sequence that repeats the 600 observations.. The objective of the Palmer Drought Severity Index (PDSI) is to provide measurements of moisture conditions that are  standardized so that comparisons using the index could be made between locations and between months (Palmer 1965) (Table 1).

![Figure 2](Fig2.png)

Figure 2: The time series of PSDI that is used as input to the model

Table 1: Classifications of Palmer Drought Severity Index.

| **Value**        | **Classifications of Palmer Drought Severity Index**     |
|--------------|-----------|
|4.0 or more | extremely wet|
|3.0 to 3.99 | Very wet|
|2.0 to 2.99 | Moderately wet|
|1.0 to 1.99 | Slightly wet|
|0.5 to 0.99 | Incipient wet spell|
|0.49 to -0.49 | Near normal|
|-0.5 to -0.99 | Incipient dry spell|
|-1.0 to -1.99 | Mild drought|
|-2.0 to -2.99 | Moderate drought|
|-3.0 to -3.99 | Severe drought|
|-4.0 or less | Extreme drought|

[^1]: I use the time series of Cibola region (for no specific reasons) which cover the period 900 to 1500. The Cibola region was occupied for a very long time which suggests that these PDSI values as inherently workable.

### 6.2 Parameter values

The parameter values used in the default case are listed in Table 2. We also list the boundaries of the parameter ranges we will explore in the sensitivity analysis. The stylized model is not based on a specific empirical data, so we tried to define a set of relative values that enable us to explore the consequences of different assumptions on the spatial and temporal population dynamics.

Table 2: Parameter values of the default version of the model

|Parameter|Description|Range|Default value|
|--------------|-----------|--------------|-----------|
|γ|Degradation factor|[0,2]|1|
|gᵣ|Regeneration level of soil a year|[0.05,0.1188] | 0.0844|
|η|Annual depletion rate of resource per household|0.5|
|α|Production elasticity|0.2|
|yₛ|Years of storage|[1, 9]|5|
|lₛ|Loss rate storage|[0,0.5]|0.25
|lf|Learning factor|[0,2]|1
|Tₘᵢₙ|Threshold of expected food available in other cell in order to migrate|[1,2]|1.5
|hₘᵢₙ|Minimum level of food a year|85
|dₘₐₓ|Maximum level of debt|[0,100000]|100
|rₘₐₓ|Radius around existing settlement as migration opportunities|[1,9]|5
|b|buffer|[0,100]|50
|bₘ|Minimum relative size of buffer|[0,1]|0.5
|rd|Annual death rate||0.02
|rb|Annual birth rate||0.03

### 6.3 Submodels

#### 6.3.1 Agricultural production

Each settlement receives rainfall each time step. Each cell _j_ has an agricultural production quality _Qⱼ_ (e.g. soil fertility). We assume that agents occupying the cell harvest an amount proportional to the production quality of the cell and the rainfall at that time step. There, the individual harvest of agent _i_, _hᵢ_ is defined as:

$$ hᵢ = \tau \cdot Q_j $$

Where _τ_ is a rainfall signal as discussed below and the production quality _Qⱼ_ depends on the available resources, labor and technology. In wet years _τ_ > 1 and the harvest of the agent is higher than an average year. Note that the rain signal _τ_ is not a linear relation with rainfall as described in the following paragraphs.

##### 6.3.1.1 Rainfall

We define a relative production level as a function of PDSI. We assume that the production level is zero in case of an extreme drought (PDSI = -8) and a normalized one if PDSI is zero. Furthermore, we assume that in wet years the production level growth towards a maximum of 50% above the yield in normal years. In line with the Mitscherlich-Baule production function (Frank et al., 1990), we define the rainfall-related production adjustment (Figure 3) as:

$$
\tau=1.5 \cdot(1-\exp ((\ln (1 / 3) / 8) \cdot(P D S I+8)))
$$

In addition to the calculation of _τ_ for the landscape we assume that there is some spatial heterogeneity in the value of _τ_. We introduce this heterogeneity by adding an annual noise factor for each cell as a normal distribution with mean zero and a standard deviation of 10% (= 0.15).

![Figure 3](Fig3.png)

_Figure 3: Relation between PDSI and relative production level according to equation (2)._

##### 6.3.1.2 Agricultural production quality

The agricultural production quality of a cell is assumed to change with the number of agents occupying the cell. More labor will lead to a modest increasing of returns to scale as they can help each other in preparing the land and harvesting resource. Furthermore, the production quality of cell depends on the relative soil quality. With increasing use of the cell, the soil quality is reduced due to erosion processes. In a formal way, the agricultural production quality of a cell is represented with a production function with inputs resources, _Rⱼ_ representing soil quality,  and _Pⱼ_ representing population size and technology, and is formulated as:

$$
Q{j}=a\cdot R_{j}\cdot P_{j}^{\alpha}
$$

With _Pⱼ_ the population level at the cell _j_ agent _i_ is located, _α_ the elasticity to labor input, and _a_ is the relative level of resources an agent can appropriate from the resource depending on the experience available within the settlement. For an elasticity of _α_ equal to 0.2, a doubling of the population on a cell leads to a 14% increase in production.

##### 6.3.1.3 Resource dynamics

The relative resource level _Rⱼ_ represents the quality of the soil. It will decline due to agricultural use and recover when left fallow. The soil quality on time step _t_ depends on the growth level _gᵣ_, the regeneration rate of the resource, the carrying capacity _Cⱼ_, and the depletion by use, depletion rate _η_ times population level _j_ _Pⱼ_ . The relative resource level is now defined as a non-linear finite difference equation with density-dependent resource regeneration:

$$
R_{j}(t)=R_{j}(t-1)+g_{r}\cdot R_{j}(t-1)\cdot\left({\frac{R_{j}(t-1)}{C_{j}}}\right)^{\gamma}\cdot(1-{\frac{R_{j}(t-1)}{C_{j}}})-\eta\cdot P_{j}(t-1)
$$

If _γ_ = 0 the relative resource follows a traditional logistic equation of resource dynamics of time. This means that without use of the land, the soil recovers back towards the carrying capacity _Cⱼ_ like a S curve, with the faster regeneration rate around half the level of  _Cⱼ_. Such a soil will always recover. However, we expect that soils can decline in their ability to recover the more it is depleted. That’s why we consider also cases where _γ_ > 0. With values of _γ_ > 0 the soil recovers back slower when depleted. This is included to mimic erosion processes. In the model simulation we used a default value of _γ_ = 1 and _gᵣ_ = 0.0844 (Figure 4). As extreme conditions we use _γ_ = 0 and _gᵣ_ = 0.05, and _γ_ = 2 and _gᵣ_ = 0.1188, where we adjust _gᵣ_ to remain the same maximum regeneration rates _(see Appendix???)_. Figure 4 shows the different effects of the parameters on the net regeneration rates. With higher values of degradation, the maximum recovery rate occurs at higher levels of the relative resource R. Thus when soil quality R is depleted to a lower level, it will recover very slowly and thus it takes much longer to recover when depletion is included (_γ_ > 0). The depletion of the soil depends only on the number of agents in the cell. It mimics loss of nutrients, vegetation, and other resources.

We acknowledge that this formulation is extremely simplistic, and more comprehensive models of the ecological processes need to be explored in the future. For now it is important that a group of agents cannot productively use a location forever since this will lead to depletion of the soils.

![Figure 4](Fig4.png)

Figure 4: Net growth curves, _Rⱼ(t+1)_ – _Rⱼ(t)_, for different assumptions of depletion rate and regeneration rate of the relative resource levels in each cell. For irreversible we assume and _γ_ = 2 and _gᵣ_ = 0.1188, for hysteresis we assume _γ_ = 1 and _gᵣ_ = 0.0844, and for reversible we use _γ_ = 0 and _gᵣ_ = 0.05.

##### 6.3.1.4 Local knowledge

Agents have a certain efficiency of using the soil quality. The efficiency rate of harvesting a depends on the cumulative experience of harvesting on that location. The more experience is cumulated, the higher the efficiency. This is formulated as follows.

$$
a={\frac{\mathit{t}l}{\mathit{t}l+\mathit{l}f}}
$$

For each agent the number of time steps staying at the cell is administrated. This enables us to calculate, _tl_ the sum of the durations of all current agents at the cell. The parameter _lf_ is the learning parameter. Agents will lose the experience of harvesting at a cell when they leave that cell. Thus if _lf_ is 1, _a_ is equal to 0.5 for a new agent exploring a pristine cell. The second year _a_ increases to 2/3 and after ten years the relative efficiency is 10/11. When more agents occupy the improvement of efficiency goes more rapidly.

#### 6.3.2 Decision making of agents

Agents are assumed to strive to consume a minimum level of resources, hmin. These resources are derived from the annual harvest and from storage. When some settlements have a shortage they will try to derive food via exchange (see below). However, settlements with a surplus will keep a minimum buffer level, _b_, in storage. Settlements with a production beyond this level may exchange. The order in which agents are updated affect the results. We update each step for all agents before moving on to the next step in the sequence: harvesting, sharing, exchange and migration.

##### 6.3.2.1 Storage

Agents store surplus for up to ys years. When agents have consumed food from their stock, it first depletes the oldest stock in storage before they will use resources from more recent years. Each year a fraction ls of the storage of the previous years is lost or not suitable for consumption. If agents share or exchange, they will only do so with the surplus of resources beyond the stock level _b_.

##### 6.3.2.2 Sharing

A settlement is defined as one or more agents on a cell. We distinguish three variations of distribution strategies within a settlement after Hegmon (1996).

- **Independent:** There is no sharing of harvest or storage among the households within a settlement.
- **Pooling:** All storage and harvest is pooled each year and distributed equally among the participants.
- **Restricted sharing:** Surplus of households is shared with households who have a shortage up to the point that those households meet the minimum requirement hmin. When surplus within a settlement is larger than the shortage, each agent with a surplus provides the same share of surplus to those agents with a shortage. When surplus in a settlement is smaller than the shortage, each agent with a shortage receives an amount so that each agent with a shortage has the same level of resources.

##### 6.3.2.3 Exchange between settlements

After we have calculated the sharing of food for all agents in all settlements, the model starts calculating the exchange of resources between settlements. Between settlements there is exchange of food in periods of stress and when the settlements have exchange relationships. For each location we calculate whether there is a shortage. We randomly draw which settlement with shortage is first to initiate exchange of resources. When there are other settlements an exchange is possible, the agents will derive resources from a settlement with surplus. This procedure is repeated until no evxchange can be made anymore before moving on to another settlement with a shortage. We acknowledge that the order in which exchange between settlements is updated might have some minor effects on the results if there are  anysettlements with shortages.

Using data from Malville (2001) we assume that a fraction of 0.02 * distance in number of cells is lost, by assuming a cell size of 10 x 10 km. However, settlements do not always provide food to other settlements who ask for this. We track for each agent how much it gives and receives during exchange interactions. When settlements exchange we calculate the average level of debt (more received than given) for each settlement. A settlement does not receive additional resources from another settlement if the average level of debt, of the cell, is beyond a maximum tolerable level of debt dmax.

##### 6.3.2.4 Moving to another cell

If an agent does not receive the minimum level of resources it requires hmin or when the storage is below a minimum level of the buffer _(bₘ*b)_, she consider to move to another location. The agent will only move to another location when it finds a location within a radius rmax that is better than the own location. The agent evaluates a location in the following way. Agents take into account that resources are depleting and calculates what the impact is of them moving to that location. It calculates the expected value of the relative resource _R_ at timestep _t+1_. To calculate the expectation, the agent uses the current level of the resource and calculates the consequence of adding one additional agent moving to that cell, using the following relationship:

$$
R_{j}^{E}(t+1)=R_{j}(t)+g_{r0}\cdot R_{j}(t)\left({\frac{R_{j}(t)}{C_{j}}}\right)^{\gamma}\cdot(1-{\frac{R_{j}(t)}{C_{j}}})-\eta\cdot\{P_{j}^{E}(t+1)+1\}
$$

This expectation depends on the expected number of agents on the cell, which is assumed to be equal to the number of agents at that moment, using asequential updating, plus the agent moving to the cell. This leads to the expected production defined as:

$$
{Q}_{j}^{E}\left(t+1\right)={a}\cdot{R}_{j}^{E}\left(t+1\right)\cdot\left\{{P}_{j}^{E}\left(t+1\right)+1\right\}^{\alpha}
$$

If the expected value of production,

$$ {Q}_{j}^{E}\left(t+1\right) > {T}_{min}\cdot {Q}_{j}\left(t\right)  $$

then the location is considered to be an option. _Tmin_ might be higher than 1 if we include transaction costs of movement and the agent wants to move to another location which is at least better than the current location. The agent moves to the best location drawn from the options and the relative values of expected production.

#### 6.3.3 Population dynamics

The total number of agents, the population of the system, changes over time. Agents have offspring and can die. Although agents represent a group of individuals, the proportional level can be mimicked by assuming that each agent has a chance to die or to generate offspring. The annual levels of death rate and birth rate are based on the amount of food produced by the agent during the year.

The death rate is defined as _rd * (2 – hi / 100)_, with _rd_ equal to 0.02, and the birth rate  is defined as _rb hi / 100_, with _rb_ equal to 0.03. This leads to a linear relation of expected population change linear in the level of corn consumption. The expected population change is zero for a consumption level of 80, and 0.25% a year when the consumption level is equal to 85, the values of hmin in the base case simulations. Thus the population growth rate is 0.25% in the maximum growth rate when no food shortages are experienced, which is in line with the maximum ‘natural’ level of population growth as observed in historical data (Cowgill, 1975).

## 7. Model implementation

The model is originally implemented in Netlogo 4.0. The code provided here is an updated version designed to work in NetLogo 6.3.0.

## References

Cowgill, G. L. (1975) On the causes and consequences of ancient and modern population changes. American Anthropologist 77(3): 505-525.<https://doi.org/10.1525/aa.1975.77.3.02a00030>

Frank, M. D., B. R. Beattie, M. E. Embleton (1990) A comparison of Alternative Crop Resource Models. American Journal of Agricultural Economics 72(3): 597-603. <https://doi.org/10.2307/1243029>

Grimm, V., U. Berger, F. Bastiansen, S. Eliassen, V. Ginot, J. Giske, J. Goss-Custard, T. Grand, S. Heinz, G. Huse, A. Huth, J.U. Jepsen, C. Jørgensen, W.M. Mooij, B. Müller,G. Pe’er, C. Piou, S.F. Railsback, A.M. Robbins, M.M. Robbins, E. Rossmanith, N. Rüger, E. Strand, S. Souissi, R.A. Stillman, R. Vabø, U. Visser, D.L. DeAngelis (2006) A standard protocol for describing individual-based and agent-based models. Ecological Modelling 198:115-126. <https://doi.org/10.1016/j.ecolmodel.2006.04.023>

Hegmon, M. (1996) Variability in Food Production, Strategies of Storage and Sharing, and the Pithouse-to-Pueblo Transition in the Northern Southwest, Pages 223-250 in J. A. Tainter and B. B. Tainter, editors. Evolving Complexity and Environmental Risk in the Prehistoric Southwest. Addison-Wesley Publishing Company, Reading, MA. <https://doi.org/10.1201/9780429492587>

Janssen, M.A. (2010) Population aggregation in ancient arid environments, Ecology and Society, 15(2): 19. <http://www.ecologyandsociety.org/vol15/iss2/art19/>

Malville, N.L. (2001) Long-Distance Transport of Bulk Goods in the Pre-Hispanic American Southwest. Journal of Anthropological Archaeology 20, 230–243 <https://doi.org/10.1006/jaar.2000.0373>

Palmer, W.C. (1965) Meteorological drought. Research Paper No. 45, U.S. Department of Commerce Weather Bureau, Washington, D.C <https://www.ncei.noaa.gov/monitoring-content/temp-and-precip/drought/docs/palmer.pdf>
