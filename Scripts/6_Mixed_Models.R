#### LINEAR MIXED MODELS #### 

#load packages
Packages.6 <- c("broom.mixed", "ggplot2", "lme4", "ggpubr", "lmerTest", "sjPlot", "car", "effects", "multcomp", "dplyr", "glmmTMB", "stats")
lapply(Packages.6, library, character.only = TRUE)

#read in metadata file
LMM.Meta<- read.csv("Input/LMM_META_FINAL.csv")
#convert species richness values to numeric (rather than factor) for models
LMM.Meta$SR<-as.numeric(LMM.Meta$SR)
class(LMM.Meta$SR)

#### GREEN SPACE TYPE AND SPECIES RICHNESS #### 

### runnning a linear mixed model to test the effect of green space type on species richness, including logged sample area as a covariate 
model.gs.sr<- glmer(SR ~ GS.Type + log(Area) + (1|Site.Code), data= LMM.Meta, family = "negative.binomial"(theta = 1))
print(model.gs.sr)
summary(model.gs.sr)
confint(model.gs.sr, level = 0.95)

# SR MODEL DIAGNOSTICS
plot(model.gs.sr, which = 1)
shapiro.test(resid(model.gs.sr))
hist(residuals(model.gs.sr))
qqnorm(residuals(model.gs.sr))
qqline(residuals(model.gs.sr))

#check effect of green space type on species richness using model outputs
Anova(model.gs.sr)
#push out model summary as csv file for plotting
tbl.1 <- broom::tidy(model.gs.sr)
tbl.1
plot(allEffects(model.gs.sr))
write.csv(tbl.1, "Output/Sr.Model.Sum.csv")

#tukey test to check pairwise comparisons of species richness of each green space type
tukey.test<-Pairwise.sr<-glht(model.gs.sr, mcp(GS.Type = "Tukey")) 
#summarizing pairwise differences across green space types
summary(Pairwise.sr) 

#### GREEN SPACE TYPE AND TREE ABUNDANCE ####

### runnning a linear mixed model to test the effect of green space type on tree abundance, including logged sample area as a covariate 
model.gs.log<- lmer(log(Abund) ~ GS.Type + log(Area) + (1|Site.Code), data = LMM.Meta)
plot(model.gs.log)

#AB MODEL DIAGNOSTICS
shapiro.test(resid(model.gs.log))
qqnorm(residuals(model.gs.log))
qqline(residuals(model.gs.log))
hist(residuals(model.gs.log))

##summary
summary(model.gs.log)
##Anova to test the effect of green space type on tree abundance
Anova(model.gs.log)
confint(model.gs.log, level = 0.95)

#push out model summary as csv file for plotting
tbl.2 <- broom::tidy(model.gs.log)
tbl.2
write.csv(tbl.2, "Output/AB.Model.Est.csv")

#pairwise comparisons
Pairwise.ab<-glht(model.gs.log, mcp(GS.Type = "Tukey")) 
summary(Pairwise.ab)

#### GS TYPE AND EVENNESS (PIE) ####
### runnning a linear mixed model to test the effect of green space type on species evenness (PIE), including logged sample area as a covariate 
model.gs.ev <- lmer(PIE ~ GS.Type + log(Area) + (1|Site.Code), data= LMM.Meta)
summary(model.gs.ev)

#Model Diagnostics
qqnorm(residuals(model.gs.ev))
qqline(residuals(model.gs.ev))
hist(residuals(model.gs.ev))
plot(residuals(model.gs.ev))
shapiro.test(resid(model.gs.ev))

##Anova to test the effect of green space type on species evenness
Anova(model.gs.ev)
#push out model summary as csv file for plotting
tbl.3 <- broom::tidy(model.gs.ev)
write.csv(tbl.3, "Output/PIE.Model.Sum.csv")

#pairwise comparison
Pairwise.ev<-glht(model.gs.ev, mcp(GS.Type = "Tukey")) 
summary(Pairwise.ev) 
confint(model.gs.ev)

#### PLOTTING MODEL ESTIMATES AND ERRORS IN ONE FIGURE ####
## here I will read back in the estimates/summaries from above to create a figure that summarizes each metric

#assigning a jitter value for all following plots
jitter <- position_jitter(width = 0.2, height = 0.01)

#### TREE ABUNDANCE PLOT ####

#read in parcel-scale means csv files and convert them from 0.04ha to per hectare 
#each of these files contain calculated mean values and standard error for parcel-scale (the scale of management/an individual park or place of worship)
ab.means<- read.csv("Output/ab.site.means.csv")
#slice file so that it only contains parks and institutions (at parcel scale)
ab.means<- ab.means %>% slice(1:23)
ab.means$GS.Type<- c("Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Park","Park","Park","Park","Park","Park","Park")
ab.means
#create a new column that converts to per hectare
ab.means$ab.ha<- (ab.means$ab.site*1.0)/0.04

##read in files with model estimates from model run above for plotting
est.ab<-read.csv("Output/AB.Model.Est.csv")
#subset only necessary variables
est.ab<-subset(est.ab, select=term:std.error)
est.ab<-est.ab[-c(5:7),]
#assigning newcolumn for GS.Type
est.ab$GS.Type<- c("Inst", "Park", "Private", "Row")
#creating estimate values based on intercept
est.ab$estimate2<-as.numeric(c("51.7319904", "47.83537124", "137.918864", "212.6770653"))
est.ab
#assigning new column with confidence intervals calculated above using function confint
est.ab$CI1<-  as.numeric(c("2.93201483", "2.62008871", "3.62654044", "4.14387949"))
est.ab$CI2<- as.numeric(c("4.9738828", "5.1442544", "6.2418056","6.5892502"))
#convert to raw values by taking the exponent
est.ab[,c(6,7)] <- exp(est.ab[,c(6,7)])
est.ab

###PLOTTING
#assigning axis labels for plot
ab.labs<- labs(x= "Green Space Type", y= "Abundance 
(trees/ha)")
#converting raw abundance values to per hectare values and adding as a new column 
LMM.Meta$ab.ha<- (LMM.Meta$Abund*1.0)/0.04
LMM.Meta

#adding column of logged abundance means
#ab.means$logged.ab.site<-log(ab.means$ab.site)
##subsetting only parks and institutional values to show parcel scale values (one park, one school etc.)
#parcel.ab.means<- ab.means[-c(24:221),]
##adding a column that shows green space type (either inst or park)
#ab.means$GS.Type<- c("Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Park","Park","Park","Park","Park","Park","Park")

##PLOT
model.ab.plot<-ggplot(LMM.Meta, aes(GS.Type, ab.ha)) 

final.ab<- model.ab.plot + theme_minimal() + geom_jitter(width= 0.4, height = 0.4, alpha= 0.5, colour= "grey", size= 3) +  geom_point(data= ab.means, aes(x= GS.Type, y= ab.ha), colour= "black", position= jitter, size= 3) +
           ab.labs + geom_pointrange(data = est.ab, aes(x= GS.Type, y= estimate2, ymin= CI1, ymax= CI2), color= "red", size= 0.5) + 
           theme(axis.title.x = element_blank(), axis.title.y = element_text(face = "bold", size = 18), axis.text.x = element_blank(), axis.text.y = element_text(size= 18)) + scale_y_log10()
final.ab

#### SPECIES RICHNESS PLOT ####

#convert species richness values to 1 hectare
LMM.Meta$sr.ha<- (LMM.Meta$SR*1)/0.04

#read in for other files and format for plotting
est.sr<- read.csv("Output/Sr.Model.Sum.csv")
#subset only necessary variables
est.sr<-subset(est.sr, select=term:std.error)
est.sr<-est.sr[-c(5:7),]
#assigning newcolumn for GS.Type
est.sr$GS.Type<- c("Inst", "Park", "Private", "Row")
#creating estimate values based on intercept
est.sr$estimate2<-as.numeric(c("18.65039452", "15.11634789", "41.75155934", "45.00495973"))
est.sr
#add new column of confidence intervals based on function confit used above
est.sr$CI1<- as.numeric(c("1.3029664", "0.8448069", "1.6837288", "1.8940959"))
est.sr$CI2<- as.numeric(c("4.55259650", "4.58690506", "5.79908822", "5.72500895"))
#convert to raw values by taking the exponent
est.sr[,c(6,7)] <- exp(est.sr[,c(6,7)])
est.sr

sr.means<- read.csv("Output/sr.site.means.csv")
#subsetting parcel scale species richness means for parks and institutions
sr.parcel.means<- sr.means[-c(24:221),]
#adding GS type to parcel scale means for plotting
sr.parcel.means$GS.Type<- c("Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Park","Park","Park","Park","Park","Park","Park")
#add a new column that adusts values to per hectare
sr.parcel.means$sr.ha<- (sr.parcel.means$sr.site*1.0)/0.04

#assigning axis labels
sr.labs<- labs(x= "", y= "Tree Species 
Richness")
#### Plotting
model.sr.plot <- ggplot(LMM.Meta, aes(GS.Type, sr.ha))
final.sr<-model.sr.plot + theme_minimal() + geom_point(data= sr.parcel.means, aes(x= GS.Type, y= sr.ha), colour= "black", position = jitter, size= 3) + geom_jitter(width= 0.3, height = 0.8, alpha= 0.5, colour= "grey", size= 3) + sr.labs +
  geom_pointrange(data = est.sr, aes(x= GS.Type, y= estimate2, ymin= CI1, ymax= CI2), size= 0.5, color= "red") + 
  theme(axis.title.x = element_blank(), axis.title.y = element_text(face = "bold", size = 18), axis.text.x = element_blank(), axis.text.y = element_text(size= 18)) + scale_y_log10()
final.sr 

#### SPECIES EVENNESS (PIE) PLOT ####

#read in summary data files
est.pie<- read.csv("Output/PIE.Model.Sum.csv")
#subset only necessary variables
est.pie<-subset(est.pie, select=term:std.error)
est.pie<-est.pie[-c(5:7),]
#assigning newcolumn for GS.Type
est.pie$GS.Type<- c("Inst", "Park", "Private", "Row")
#creating estimate values based on intercept
est.pie$estimate2<-as.numeric(c("0.70623896", "0.68712261", "0.76612525", "0.69592958"))
est.pie
#assigning new column with confidence intervals calculated above using function confint
est.pie
#add new column of confidence intervals based on function confit used above
est.pie$CI1<- as.numeric(c("0.24082061", "0.13320129", "0.17207884", "0.14196409"))
est.pie$CI2<- as.numeric(c("1.17677719", "1.24829664", "1.36523348", "1.25458288"))

pie.means<- read.csv("Output/pie.site.means.csv")
#subsetting parcel scale species evenness (PIE) means for parks and institutions
pie.parcel.means<- pie.means[-c(24:221),]
#adding GS type to parcel scale means for plotting
pie.parcel.means$GS.Type<- c("Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Inst","Park","Park","Park","Park","Park","Park","Park")

##Plotting
#assigning axis labels
pie.labs<- labs(x= "Green Space Type", y= "Tree Species 
Evenness")

model.pie.plot<-ggplot(LMM.Meta, aes(GS.Type,PIE)) 
final.ev<-model.pie.plot  + theme_minimal() + geom_point(data= pie.parcel.means, mapping = aes(x= GS.Type, y= PIE.site), colour= "black", position= jitter, size= 3) + geom_jitter(width= 0.2, height = 0.01, alpha= 0.5, colour= "grey", size= 3) + pie.labs +
  theme(axis.title.x = element_blank(), axis.title.y = element_text(face = "bold", size = 18, colour = "black"), axis.text.x = element_text(size= 20, face= "bold", colour= "black"), axis.text.y = element_text(size= 18)) +
  geom_pointrange(data = est.pie, mapping = aes(x = GS.Type, y = estimate2, ymin = CI1, ymax = CI2), size=0.5, color="red")
final.ev

#### Total with ALL metrics
#WRAPPING INTO ONE FIGURE

model.figure<- ggarrange(final.ab, final.sr, final.ev,
                         nrow= 3, ncol= 1,
                         labels = c("A", "B", "C"), font.label =  list(size = 18), hjust = -0.5, vjust = 1.1)
model.figure

