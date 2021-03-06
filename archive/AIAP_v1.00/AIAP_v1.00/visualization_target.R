#!/usr/bin/env Rscript
args=commandArgs()

name=args[6]
name=paste(name,"result",sep=".")
refpath=args[7]
beta=args[11]
rtime=args[12]
image_id=args[13]

library(ggplot2)
library(cowplot)

# chromosome distribution
chr=read.table(paste("step2.2_chrom_count",name,sep="_"))
if("chrM"%in%chr$V1==TRUE) {
  r=as.numeric(rownames(chr[which(chr$V1=='chrM'),]))
  chr=rbind(chr[-r,],chr[r,])
  rownames(chr)=NULL
}
chr$V1=factor(c(nrow(chr):1),labels=rev(as.character(chr$V1)))
chr$V2=chr$V2/sum(chr$V2)
chr$V3=chr$V3/sum(chr$V3)
colnames(chr)=c("chromosome","Total mapped reads","Non-redundant uniquely mapped reads")
chr=data.frame(chr[1],stack(chr[2:3]))

png("plot2.2_reads_distri_in_chrom.png",height=640,width=6600,res=300)
ggplot(chr,aes(x=ind,y=values,fill=chromosome))+
  ggtitle("Stacked barplotm of reads percentage in each chromosome")+
  geom_bar(stat="identity",color="black")+
  scale_y_continuous(name="Percentage of reads")+
  scale_x_discrete(name="")+
  guides(fill=guide_legend(nrow=1,byrow=TRUE,reverse=T))+
  theme_bw()+theme_classic()+coord_flip()+
  theme(plot.title=element_text(size=14,family="Tahoma",face="bold",hjust=0.5),
        text=element_text(size=12,family="Tahoma"),
        axis.title=element_text(face="bold"),
        axis.text.x=element_text(size=10,face="bold"),
        axis.text.y=element_text(size=10,face="bold"),
        legend.text=element_text(size=10,face="bold"),
        legend.title=element_text(size=10,face="bold"),
        legend.position="bottom")
dev.off()

# saturation analysis
saturate=read.table(paste("step4.4_saturation",name,sep="_"),header=T,sep='\t')
saturate=saturate[,-2]
colnames(saturate)=c("depth","peak","percentage","marker")

png("plot4.5_saturation.png",height=2300,width=2800,res=300)
plot=ggplot(saturate,aes(x=depth,y=100*percentage))+
  geom_point()+geom_line(size=1)+expand_limits(x=0,y=0)+
  geom_text(aes(label=peak),hjust=0,vjust=1.4,family="Tahoma",fontface=2,size=3)+
  ggtitle("Line chart of recaptured coverage ratio labeled with \n numbers of peaks by subsampling original library")+
  scale_x_continuous(name="Percentage of original library size",breaks=seq(0,100,by=10))+
  geom_vline(xintercept=50,linetype="dotted",size=1)+
  theme_bw()+theme_classic()+
  theme(plot.title=element_text(size=14,family="Tahoma",face="bold",hjust=0.5),
        text=element_text(size=12,family="Tahoma"),
        axis.title=element_text(face="bold"),
        axis.text.x=element_text(size=10,face="bold"),
        axis.text.y=element_text(size=10,face="bold"))
if(max(saturate$percentage)<=1) {
  plot+scale_y_continuous(name="Percentage of coverage ratio in original peaks",limits=c(0,100))
} else {
  plot+scale_y_continuous(name="Percentage of coverage ratio in original peaks")
}
dev.off()

# peak legth distribution
peakl=read.table(paste("step3.4_peak_length_distri",name,sep="_"))
peakl=rbind(peakl[which(peakl$V1<1500),],c(1500,sum(peakl[which(peakl$V1>=1500),2])))
peakl$V2=peakl$V2/sum(peakl$V2)

dense_plot=ggplot(peakl,aes(x=V1,y=..scaled..,weight=V2))+geom_density(size=1,adjust=0.2)+
  ggtitle("Density plot of peaks length distribution (Adjust=0.2)")+
  theme_bw()+theme_classic()+expand_limits(x=0,y=0)+
  scale_y_continuous(name="Density",limits=c(0,1))+
  scale_x_continuous(name="Length of peaks",breaks=seq(0,max(peakl$V1),by=150))+
  theme(plot.title=element_text(size=14,family="Tahoma",face="bold",hjust=0.5),
        text=element_text(size=12,family="Tahoma"),
        axis.title=element_text(face="bold"),
        axis.text.x=element_text(size=10,face="bold"),
        axis.text.y=element_text(size=10,face="bold"))

dense_length=as.data.frame(ggplot_build(dense_plot)$data[[1]])
dense_length=data.frame(length_of_peaks=dense_length$x,density=dense_length$y)

png("plot3.3_peak_length.png",height=2000,width=3000,res=300)
dense_plot
dev.off()

# insertion distribution
insert=read.table(paste("step3.1_insertion_distri",name,sep="_"))
insert$V2=insert$V2/sum(insert$V2)

dense_plot=ggplot(insert,aes(x=V1,y=..scaled..,weight=V2))+geom_density(size=1,adjust=0.2)+
  ggtitle("Density plot of insertion size distribution (Adjust=0.2)")+
  theme_bw()+theme_classic()+
  scale_y_continuous(name="Density",limits=c(0,1))+
  scale_x_continuous(name="Insertion size",limits=c(0,500))+
  theme(plot.title=element_text(size=14,family="Tahoma",face="bold",hjust=0.5),
        text=element_text(size=12,family="Tahoma"),
        axis.title=element_text(face="bold"),
        axis.text.x=element_text(size=10,face="bold"),
        axis.text.y=element_text(size=10,face="bold"))

dense_insert=as.data.frame(ggplot_build(dense_plot)$data[[1]])
dense_insert=data.frame(insertion_size=dense_insert$x,density=dense_insert$y)

png("plot3.1_insertion_size.png",height=1800,width=2400,res=300)
dense_plot
dev.off()

# dedup
ref.dedup=read.table(paste(refpath,'merged_dedup_percentage.txt',sep='/'),sep='\t',header=T) ####
i=1
filename=c()
ratio=c() 
while(i<=dim(ref.dedup)[1]) {
  filename=c(filename,strsplit(as.character(ref.dedup[i,1]),'_1',fixed=T)[[1]][1])
  ratio=c(ratio,100-(ref.dedup[i,2]+ref.dedup[i+1,2])/2)
  i=i+2
}
ref.dedup=data.frame(filename,ratio,class="ENCODE PE")
dedup=read.table(paste("step1.3_dedup_percentage",name,sep="_"),header=T,sep='\t')
if(dim(dedup)[1]>1) {
  dedup=data.frame(filename=strsplit(as.character(dedup[1,1]),'_1',fixed=T)[[1]][1],ratio=100-(dedup[1,2]+dedup[2,2])/2,class='Sample')
  data_type="Paired-end data"
} else {
  dedup=data.frame(filename=strsplit(as.character(dedup[1,1]),'_1',fixed=T)[[1]][1],ratio=100-dedup[1,2],class='Sample')
  data_type="Single-end data"
}
ref.dedup=rbind(ref.dedup,dedup)

# enrichment
ref.enrich2=read.table(paste(refpath,'merged_coding_promoter_peak_enrichment.txt',sep='/'),header=T,sep='\t') ####
enrich2=read.table(paste("step4.2_enrichment_ratio_in_promoter",name,sep="_"),header=T,sep='\t')
ref.enrich2=data.frame(enrichment_ratio=ref.enrich2[,5],class="ENCODE PE")
enrich2=data.frame(enrichment_ratio=enrich2[,5],class="Sample")
ref.enrich2=rbind(ref.enrich2,enrich2)
ref.enrich2[,3]="Enrichment ratio in coding promoter regions"

ref.enrich3=read.table(paste(refpath,'merged_sub10M_enrichment.txt',sep='/'),header=T,sep='\t') ####
enrich3=read.table(paste("step4.2_sub10M_enrichment",name,sep="_"),header=T,sep='\t')
ref.enrich3=data.frame(enrichment_ratio=ref.enrich3[,5],class="ENCODE PE")
enrich3=data.frame(enrichment_ratio=enrich3[,5],class="Sample")
ref.enrich3=rbind(ref.enrich3,enrich3)
ref.enrich3[,3]="Subsampled 10M enrichment ratio"

test=rbind(ref.enrich2,ref.enrich3)

png("plot4.2.2_peaks_enrichment_ratio.png",height=1800,width=2800,res=300)
options(warn=-1)
plot=ggplot(test,aes(x=class,y=enrichment_ratio,fill=class))+
  stat_boxplot(geom="errorbar",size=1,width=0.3,aes(colour=class))+
  geom_boxplot(outlier.shape=NA,width=0.3,lwd=1,fatten=1,aes(colour=class))+
  scale_x_discrete(name="")+
  ggtitle("Boxplot of peaks enrichment ratio")+
  scale_fill_manual(values=c(`ENCODE PE`="grey",Sample="red"))+
  scale_colour_manual(values=c(`ENCODE PE`="black",Sample="red"))+
  facet_grid(.~V3)+theme(legend.position="none")+
  theme(plot.title=element_text(size=14,family="Tahoma",face="bold",hjust=0.5),
        text=element_text(size=12,family="Tahoma"),
        strip.text.x=element_text(size=12,face="bold"),
        axis.title=element_text(face="bold"),
        axis.text.x=element_text(size=10,face="bold",colour=c(`ENCODE PE`="black",Sample="red")),
        axis.text.y=element_text(size=10,face="bold"))
if(enrich3[1,1]<130) {
  plot+scale_y_continuous(name="Enrichment ratio",limits=c(0,100))
} else {
  plot+scale_y_continuous(name="Enrichment ratio")
}
options(warn=0)
dev.off()

# mapping status
ref.map=read.table(paste(refpath,'merged_mapping_status.txt',sep='/'),header=T,sep='\t') ####
ref.map=ref.map[,c(2,7,10,12)]
ref.map=data.frame(ref.map,class="ENCODE PE")
map=read.table(paste("QC_data_collection",name,sep="_"),header=T,sep='\t')
map=map[,c(2,7,10,12)]
map=data.frame(map,class="Sample")
ref.map=rbind(ref.map,map)
#ref.map$after_align_dup=1-ref.map$after_align_dup
#map$after_align_dup=1-map$after_align_dup

png("plot4.3_PCR_duplicates_percentage.png",height=2000,width=1400,res=300)
options(warn=-1)
plot=ggplot(ref.map,aes(x=class,y=100*after_align_dup,fill=class))+
  stat_boxplot(geom="errorbar",size=1,width=0.3,aes(colour=class))+
  geom_boxplot(outlier.shape=NA,width=0.3,lwd=1,fatten=1,aes(colour=class))+
  scale_x_discrete(name="")+
  ggtitle("Boxplot of PCR duplicates percentage")+
  scale_fill_manual(values=c(`ENCODE PE`="grey",Sample="red"))+
  scale_colour_manual(values=c(`ENCODE PE`="black",Sample="red"))+
  theme_bw()+theme_classic()+theme(legend.position="none")+
  theme(plot.title=element_text(size=14,family="Tahoma",face="bold",hjust=0.5),
        text=element_text(size=12,family="Tahoma"),
        axis.title=element_text(face="bold"),
        axis.text.x=element_text(size=10,face="bold",colour=c(`ENCODE PE`="black",Sample="red")),
        axis.text.y=element_text(size=10,face="bold"))
if(1-map$after_align_dup*100<30) {
  plot+scale_y_continuous(name="Percentage of PCR duplicates",limits=c(0,30))
} else {
  plot+scale_y_continuous(name="Percentage of PCR duplicates")
}
options(warn=0)
dev.off()

png("plot4.1_RUP.png",height=2000,width=1400,res=300)
options(warn=-1)
plot=ggplot(ref.map,aes(x=class,y=rup_ratio,fill=class))+
  stat_boxplot(geom="errorbar",size=1,width=0.3,aes(colour=class))+
  geom_boxplot(outlier.shape=NA,width=0.3,lwd=1,fatten=1,aes(colour=class))+
  scale_x_discrete(name="")+
  ggtitle("Boxplot of reads under peaks ratio")+
  scale_fill_manual(values=c(`ENCODE PE`="grey",Sample="red"))+
  scale_colour_manual(values=c(`ENCODE PE`="black",Sample="red"))+
  theme_bw()+theme_classic()+theme(legend.position="none")+
  theme(plot.title=element_text(size=14,family="Tahoma",face="bold",hjust=0.5),
        text=element_text(size=12,family="Tahoma"),
        axis.title=element_text(face="bold"),
        axis.text.x=element_text(size=10,face="bold",colour=c(`ENCODE PE`="black",Sample="red")),
        axis.text.y=element_text(size=10,face="bold"))
if(map$rup_ratio<50) {
  plot+scale_y_continuous(name="Reads under peaks ratio",limits=c(0,50))
} else {
  plot+scale_y_continuous(name="Reads under peaks ratio")
}
options(warn=0)
dev.off()

colnames(ref.map)[1:2]=c("Total reads","Non-redundant uniquely mapped reads")
test=data.frame(ref.map[5],stack(ref.map[1:2]),row.names=NULL)

png("plot3.1_library_reads_distri.png",height=1800,width=2800,res=300)
plot=ggplot(test,aes(x=class,y=values,fill=class))+
  stat_boxplot(geom="errorbar",size=1,width=0.3,aes(colour=class))+
  geom_boxplot(outlier.shape=NA,width=0.3,lwd=1,fatten=1,aes(colour=class))+
  scale_x_discrete(name="")+
  ggtitle("Boxplot of reads distribution")+
  scale_fill_manual(values=c(`ENCODE PE`="grey",Sample="red"))+
  scale_colour_manual(values=c(`ENCODE PE`="black",Sample="red"))+
  facet_grid(.~ind)+theme(legend.position="none")+
  theme(plot.title=element_text(size=14,family="Tahoma",face="bold",hjust=0.5),
        text=element_text(size=12,family="Tahoma"),
        strip.text.x=element_text(size=12,face="bold"),
        axis.title=element_text(face="bold"),
        axis.text.x=element_text(size=10,face="bold",colour=c(`ENCODE PE`="black",Sample="red")),
        axis.text.y=element_text(size=10,face="bold"))
if(map[1,1]<10e+7) {
  plot+scale_y_continuous(name="Number of reads",limits=c(0,10e+7))
} else {
  plot+scale_y_continuous(name="Number of reads")
}
dev.off()

# Yield plot
yield=read.table(paste("step2.3_yield",name,sep="_"),sep='\t',header=T)
yield=yield[yield$TOTAL_READS<=1e8,]

png("plot2.3_yield_distinction.png",height=1800,width=2600,res=300)
ggplot(yield,aes(x=TOTAL_READS,y=EXPECTED_DISTINCT))+
  geom_ribbon(aes(ymin=yield[,3],ymax=yield[,4],x=TOTAL_READS,fill="Range of confidence interval"),alpha=0.5)+
  geom_point()+geom_line(size=1)+
  geom_point(aes(x=map[,1],y=map[,2],color="red"),show.legend=F)+
  ggtitle("Line chart of yield distinction")+
  scale_x_continuous(name="Total reads")+
  scale_y_continuous(name="Expected distinction")+
  theme_bw()+theme_classic()+
  scale_fill_manual("Reference ribbon",values="grey")+
  theme(plot.title=element_text(size=14,family="Tahoma",face="bold",hjust=0.6),
        text=element_text(size=12,family="Tahoma"),
        axis.title=element_text(face="bold"),
        axis.text.x=element_text(size=10,face="bold"),
        axis.text.y=element_text(size=10,face="bold"),
        legend.text=element_text(size=8,face="bold"),
        legend.title=element_text(size=12,face="bold"),
        legend.position="bottom")
dev.off()

# promoter
promoter=read.table(paste("step4.5_promoter_percentage",name,sep="_"),header=T,sep='\t')
peak=data.frame(group=c("Peaks in promoter region","Peaks in non-promoter region"),value=as.numeric(promoter[1,1:2]))
read=data.frame(group=c("Reads under peaks in promoter region","Reads under peaks in non-promoter region"),value=as.numeric(promoter[1,3:4]))

blank_theme=theme_minimal()+theme(
  axis.title.x=element_blank(),
  axis.title.y=element_blank(),
  panel.border=element_blank(),
  panel.grid=element_blank(),
  axis.ticks=element_blank(),
  plot.title=element_text(size=14, face="bold"))

p1=ggplot(peak,aes(x="",y=value,fill=group))+
  geom_bar(width=1,stat="identity")+
  coord_polar("y",start=0)+
  ggtitle("Pie chart of peaks distribution")+
  scale_fill_grey()+blank_theme+
  theme(plot.title=element_text(size=14,family="Tahoma",face="bold",hjust=0.5),
        text=element_text(size=12,face="bold",family="Tahoma"),
        axis.text.x=element_blank())+
  geom_text(aes(y=value/2+c(0,cumsum(value)[-length(value)]),label=value),size=5,family="Tahoma",fontface="bold")

p2=ggplot(read,aes(x="",y=value,fill=group))+
  geom_bar(width=1,stat="identity")+
  coord_polar("y",start=0)+
  ggtitle("Pie chart of reads distribution")+
  scale_fill_grey()+blank_theme+
  theme(plot.title=element_text(size=14,family="Tahoma",face="bold",hjust=0.5),
        text=element_text(size=12,face="bold",family="Tahoma"),
        axis.text.x=element_blank())+
  geom_text(aes(y=value/2+c(0,cumsum(value)[-length(value)]),label=value),size=5,family="Tahoma",fontface="bold")

png("plot4.6_promoter-peak_count.png",height=1500,width=5000,res=300)
options(warn=-1)
plot_grid(p2,p1,ncol=2,nrow=1,rel_widths=c(1,0.88))
options(warn=0)
dev.off()

options(warn=-1)
top=try(read.table(paste("step4.5_bin",name,sep="_"),sep='\t'),silent=T)
options(warn=0)
if(class(top)!="try-error"){
  top=data.frame(rank=as.numeric(top$V1),index=as.numeric(top$V2))
  
  png("plot4.6_promoter_distribution_among_peaks.png",height=1800,width=3200,res=300)
  print(ggplot(top,aes(sort(rank),index))+geom_density(stat="identity")+
    ggtitle("Percentage of promoter regions")+
    theme_bw()+theme_classic()+
    scale_y_continuous(name="Percentage of promoter regions",limits=c(0,1))+
    scale_x_continuous(name="Percentage of Top peaks")+
    theme(plot.title=element_text(size=14,family="Tahoma",face="bold",hjust=0.5),
          text=element_text(size=12,family="Tahoma"),
          axis.title=element_text(face="bold"),
          axis.text.x=element_text(size=8,face="bold"),
          axis.text.y=element_text(size=8,face="bold")))
  dev.off()
} else {
  cat("Warning message:\nNumber of peaks in promoter regions is smaller than 100! Skip plot4.6_promoter_distribution_among_peaks.png!")
}

# TXT report generation
name=args[6]
report=list(Library=name)
name=paste(name,"result",sep=".")

genome=args[8]
report=append(report,list(Pipeline.version=beta,Genome=genome,Data.type=data_type))

ref.useful=read.table(paste(refpath,'merged_useful_reads.txt',sep='/'),header=T,sep='\t')
useful=read.table(paste("step3.1_useful_reads",name,sep="_"),header=T,sep='\t')

ref.map=read.table(paste(refpath,'merged_mapping_status.txt',sep='/'),header=T,sep='\t') ####
refer=c(paste(round(mean(ref.map$total)),'(SD:',round(sd(ref.map$total)),')',sep=''))
refer=c(refer,paste(round(mean(ref.map$mapped)),'(SD:',round(sd(ref.map$mapped)),')',sep=''))

map=read.table(paste("QC_data_collection",name,sep="_"),header=T,sep='\t')
samples=as.numeric(c(map$total,map$mapped))

ref.chr=read.table(paste(refpath,'merged_chrom_count.txt',sep='/'),header=T,sep='\t')
rownames(ref.chr)=ref.chr$chrom
ref.chr=ref.chr[,-1]
ref.chr=as.matrix(ref.chr[,seq(4,269,5)])

chr=read.table(paste("step2.2_chrom_count",name,sep="_"),sep='\t')
if(genome!="danRer10" && genome!="danRer11") {
  refer=c(refer,"8.34%(SD:5.06%)")
  refer=c(refer,paste(round(mean(ref.map[,7])),'(SD:',round(sd(ref.map[,7])),')',sep=''))
  refer=c(refer,paste(round(mean( as.numeric(ref.chr[21,][seq(6, length(ref.chr[21,]), 5)]) ),4),'%(SD:',round(sd( as.numeric(ref.chr[21,][seq(6, length(ref.chr[21,]), 5)]) ),4),'%)',sep=''))
  refer=c(refer,paste(round(mean( as.numeric(ref.chr[22,][seq(6, length(ref.chr[22,]), 5)]) ),4),'%(SD:',round(sd(  as.numeric(ref.chr[22,][seq(6, length(ref.chr[22,]), 5)]) ),4),'%)',sep=''))
  refer=c(refer,paste(round(mean(ref.useful[,5])),'(SD:',round(sd(ref.useful[,5])),')',sep=''))
  
  samples=c(samples,paste(round(as.numeric(args[10]),4)*100,'%',sep=''),as.numeric(map[,7]),paste(round(chr[which(chr[,1]=='chrX'),3]/map[,7],4)*100,'%',sep=''),paste(round(chr[which(chr[,1]=='chrY'),3]/map[,7],4)*100,'%',sep=''),useful[,5])
  library=data.frame(samples,refer)
  colnames(library)=c("Sample","ENCODE PE")
  rownames(library)=c("Total reads","Mapped reads","Percentage of uniquely mapped reads in chrM","Non-redundant uniquely mapped reads","Percentage of reads in chrX","Percentage of reads in chrY","Useful single ends")
  report=append(report,list(Library.size=library))
} else {
  refer=c(refer,"8.34%(SD:5.06%)")
  refer=c(refer,paste(round(mean(ref.map[,7])),'(SD:',round(sd(ref.map[,7])),')',sep=''))
  refer=c(refer,paste(round(mean(ref.useful[,5])),'(SD:',round(sd(ref.useful[,5])),')',sep=''))
  
  samples=c(samples,paste(round(as.numeric(args[10]),4)*100,'%',sep=''),as.numeric(map[,7]),useful[,5])
  library=data.frame(samples,refer)
  colnames(library)=c("Sample","ENCODE PE")
  rownames(library)=c("Total reads","Mapped reads","Percentage of uniquely mapped reads in chrM","Non-redundant uniquely mapped reads","Useful single ends")
  report=append(report,list(Library.size=library))
}

refer=paste(round(mean(ref.dedup[which(ref.dedup$class=='ENCODE PE'),2]),2),'%(SD:',round(sd(ref.dedup[which(ref.dedup$class=='ENCODE PE'),2]),2),'%)',sep='')
refer=c(refer,paste(round(mean(1-ref.map$after_align_dup),4)*100,'%(SD:',round(sd(1-ref.map$after_align_dup),4)*100,'%)',sep=''))
samples=c(paste(round(ref.dedup[which(ref.dedup$class=='Sample'),2],2),'%',sep=''),paste((1-map$after_align_dup)*100,'%',sep=''))
library=data.frame(samples,refer)
colnames(library)=c("Sample","ENCODE PE")
rownames(library)=c("Before alignment library duplicates percentage","After alignment PCR duplicates percentage")
report=append(report,list(Library.complexity=library))

ref.peak=read.table(paste(refpath,'merged_saturation_collection.txt',sep='/'),header=T,sep='\t')
ref.peak=ref.peak[,-1]
ref.peak=ref.peak[11,seq(2,161,3)]
refer=as.numeric(ref.peak[1,])
refer=paste(round(mean(refer)),'(SD:',round(sd(refer)),')',sep='')
refer=c(paste(round(mean(ref.useful[,4]),2)*100,'%(SD:',round(sd(ref.useful[,4]),2)*100,'%)',sep=''),refer)
refer=c(refer,paste(round(mean(ref.map$rup_ratio),2),'%(SD:',round(sd(ref.map$rup_ratio),2),'%)',sep=''))
refer=c(refer,paste(round(mean(ref.enrich2[which(ref.enrich2$class=='ENCODE PE'),1]),2),'(SD:',round(sd(ref.enrich2[which(ref.enrich2$class=='ENCODE PE'),1]),2),')',sep=''))
refer=c(refer,paste(round(mean(ref.enrich3[which(ref.enrich3$class=='ENCODE PE'),1]),2),'(SD:',round(sd(ref.enrich3[which(ref.enrich3$class=='ENCODE PE'),1]),2),')',sep=''))
ref.dicho=read.table(paste(refpath,'merged_bg_dichoto.txt',sep='/'),header=T,sep='\t')
ref.dicho=data.frame(ref.dicho[2:4],class="ENCODE PE")
dicho=read.table(paste("step4.5_dichoto_bg",name,sep="_"),sep='\t')
dicho=data.frame(dicho,class="Sample")
colnames(dicho)=colnames(ref.dicho)
ref.dicho=rbind(ref.dicho,dicho)
colnames(ref.dicho)[1:3]=c("RPKM smaller than 0.15","RPKM smaller than 0.3","RPKM larger than 0.3")
refer=c(refer,paste(round(mean(ref.dicho[,3]),2),'%(SD:',round(sd(ref.dicho[,3]),2),'%)',sep=''))

samples=c(paste(useful[,4]*100,'%',sep=''),as.numeric(saturate[11,2]))
samples=c(samples,paste(round(map$rup_ratio,2),'%',sep=''),round(ref.enrich2[which(ref.enrich2$class=='Sample'),1],2),round(ref.enrich3[which(ref.enrich3$class=='Sample'),1],2))
samples=c(samples,paste(round((100-dicho[,2]),2),'%',sep=''))

library=data.frame(samples,refer)
colnames(library)=c("Sample","ENCODE PE")
rownames(library)=c("Useful reads ratio","Number of peaks","Reads under peaks ratio","Enrichment ratio in coding promoter regions","Subsampled 10M enrichment ratio","Percentage of background RPKM larger than 0.3777")
report=append(report,list(Enrichment=library))

name=args[6]
capture.output(print(report),file=paste(name,"report.txt",sep='_'))

# JSON file generation
if(is.na(image_id)) {
  part1=data.frame(name,genome,data_type,beta,"MD5ToBeChange",rtime)
  colnames(part1)=c("file_name","genome","read_type","pipe_version","bash_script_MD5","running_time")
  file=list(`data_information`=part1)
} else {
  part1=data.frame(name,genome,data_type,beta,image_id,"MD5ToBeChange",rtime)
  colnames(part1)=c("file_name","genome","read_type","pipe_version","Docker_image_id","bash_script_MD5","running_time")
  file=list(`data_information`=part1)
}

score_table=read.table(paste("step4.6_score_calculation_",name,".result", sep=""),sep='\t', header=1, colClasses = c("character", "character", "numeric"))
score_table=score_table[c('iterm','score')]
score_table=rbind(c("total_score", sum(score_table$score)), score_table) 
score_exp=data.frame(t(score_table$score))
colnames(score_exp)=t(score_table$iterm)
score_exp[] <- lapply(score_exp, function(x) {
    if(is.factor(x)) as.numeric(as.character(x)) else x
})
part_score=data.frame(score_exp)
file=append(file, list(`score_matrix`=part_score))

part2=data.frame("cutadapt","1.16",as.numeric(args[9]),"FastQC","0.11.7")
colnames(part2)=c("program1","program1_version","written_reads_by_cutadapt","program2","program2_version")
file=append(file,list(`pre_alignment_stats`=part2))

part3=data.frame("bwa","0.7.16a","bwa mem","methylQA","0.2.1","methylQA atac",map$total,map$mapped,map[,6],map[,7],useful[,5])
colnames(part3)=c("alignment_program","alignment_program_version","alignment_program_parameters","post_alignment_program","post_alignment_program_version","post_alignment_program_parameters","total_reads","mapped_reads","uniquely_mapped_reads","non-redundant_mapped_reads","useful_single_ends")
file=append(file,list(`mapping_stats`=part3))

part9=data.frame(round(ref.dedup[which(ref.dedup$class=='Sample'),2],2)/100,map$after_align_dup)
colnames(part9)=c("before_alignment_library_duplicates_percentage","after_alignment_PCR_duplicates_percentage")
file=append(file,list(`library_complexity`=part9))

part4=data.frame(paste("?",paste(dense_insert$insertion_size,sep="",collapse=","),"?",sep=""),paste("?",paste(dense_insert$density,sep="",collapse=","),"?",sep=""))
colnames(part4)=c("insertion_size","density")
file=append(file,list(`insertion_size_distribution`=part4))

autosome=chr[which(!chr$V1%in%c("chrM","chrX","chrY")),c(1,3)]
autosome$V3=round(autosome$V3/map[,7],4)
autosome$V1=paste("@",autosome$V1,"@",sep="")
autosome=paste(autosome$V1,autosome$V3,sep=": ")
autosome=paste("!",paste(autosome,sep="",collapse=", "),"!",sep="")

if(genome!="danRer10" && genome!="danRer11") {
  part5=data.frame(round(as.numeric(args[10]),4),round(chr[which(chr[,1]=='chrX'),3]/map[,7],4),round(chr[which(chr[,1]=='chrY'),3]/map[,7],4),autosome)
  colnames(part5)=c("percentage_of_uniquely_mapped_reads_in_chrM","percentage_of_non-redundant_uniquely_mapped_reads_in_chrX","percentage_of_non-redundant_uniquely_mapped_reads_in_chrY","Percentage_of_non-redundant_uniquely_mapped_reads_in_autosome")
  file=append(file,list(`mapping_distribution`=part5))
} else {
  part5=data.frame(round(as.numeric(args[10]),4),autosome)
  colnames(part5)=c("percentage_of_uniquely_mapped_reads_in_chrM","percentage_of_non-redundant_uniquely_mapped_reads_in_autosome")
  file=append(file,list(`mapping_distribution`=part5))
}

part6=data.frame("macs2","--keep-dup 1000 --nomodel --shift 0 --extsize 150","qvaule",0.01,map$rup_ratio/100.0,map[,11],promoter[1,1],promoter[1,2])
colnames(part6)=c("peak_calling_software","peak_calling_parameters","peak_threshold_parameter","peak_threshold","reads_percentage_under_peaks","reads_number_under_peaks","peaks_number_in_promoter_regions","peaks_number_in_non-promoter_regions")
file=append(file,list(`peak_analysis`=part6))

part7=data.frame(paste("?",paste(saturate[,1],sep="",collapse=","),"?",sep=""),paste("?",paste(saturate[,2],sep="",collapse=","),"?",sep=""),paste("?",paste(saturate[,3],sep="",collapse=","),"?",sep=""))
colnames(part7)=c("sequence_depth","peaks_number","percentage_of_peak_region_recaptured")
file=append(file,list(`saturation`=part7))

part8=data.frame(round(ref.enrich2[which(ref.enrich2$class=='Sample'),1],2),round(ref.enrich3[which(ref.enrich3$class=='Sample'),1],2),1-round(dicho[,2],2)/100)
colnames(part8)=c("enrichment_score_in_coding_promoter_regions","subsampled_10M_enrichment_score","percentage_of_background_RPKM_larger_than_0.3777")
file=append(file,list(`enrichment`=part8))

part11=data.frame(paste("?",paste(yield[,1],sep="",collapse=","),"?",sep=""),paste("?",paste(yield[,2],sep="",collapse=","),"?",sep=""),paste("?",paste(yield[,3],sep="",collapse=","),"?",sep=""),paste("?",paste(yield[,4],sep="",collapse=","),"?",sep=""))
colnames(part11)=c("total_reads","expected_distinction","lower_0.95_confidnece_interval","upper_0.95_confidnece_interval")
file=append(file,list(`yield_distribution`=part11))

part12=data.frame(paste("?",paste(dense_length$length_of_peaks,sep="",collapse=","),"?",sep=""),paste("?",paste(dense_length$density,sep="",collapse=","),"?",sep=""))
colnames(part12)=c("peak_length","density")
file=append(file,list(`peak_length_distribution`=part12))

file=list(name=file)
names(file)="Sample_QC_info"

test=try(library(jsonlite),silent=T)

capture.output(toJSON(file,pretty=T),file=paste(name,"report.json",sep='_'))





