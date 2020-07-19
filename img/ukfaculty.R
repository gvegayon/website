library(netplot)
library(magrittr)
data(UKfaculty, package="igraphdata")

set.seed(33)
uk2 <- igraph::rewire(UKfaculty, igraph::keeping_degseq(niter=80))
uk2 <- igraph::delete_edges(uk2, sample.int(igraph::ecount(uk2), 200))

graphics.off()
oldpar <- par(lwd=10)
svg(file = "ukfaculty.svg", width = 7, height=7)
#nplot(UKfaculty, vertex.color = "gray40", edge.width = 2)
set.seed(1223);nplot(
  uk2,
  vertex.color = "#B22222",
  edge.width = 2,
  edge.line.breaks=4,
  edge.color = ~ ego(alpha=.1) + alter,
  edge.color.alpha=c(.1, .5),
  edge.color.mix=.9,
  layout = igraph::layout_with_fr(uk2)# igraph::layout_with_sugiyama(UKfaculty)$layout
)
dev.off()
par(oldpar)

