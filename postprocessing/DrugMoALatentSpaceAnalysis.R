library(tidyverse)
library(gg3D)
library(ggpubr)
library(patchwork)
library(ggplot2)
library(colorblindr)
library(viridis)
library(RColorBrewer)
library(lsa)

#Process function to add condition ids and duplicate ids
pca_visualize <- function(embbedings,
                           dim=2,
                           scale=F,
                           visualize = 'cmap_name',
                           top_drugs = 7,
                           show_plot=F,
                           title=NULL,
                           title_pos = element_blank(),
                           colors=NULL,
                           col_breaks=NULL,
                           size_points = 2,
                           verbose=F){
  if ('moa' %in% colnames(embbedings)){
    sample_info <- embbedings %>% select(sig_id,cmap_name,pert_id,cell,moa,drugs_per_moa,pert_dose,pert_itime,tas) %>% unique()
    embs <- embbedings %>% select(-cell,-cmap_name,-duplIdentifier,-moa,-pert_id,-drugs_per_moa,-pert_dose,-pert_itime,-tas) %>% unique()
  }else{
    sample_info <- embbedings %>% select(sig_id,cmap_name,pert_id,cell,pert_dose,pert_itime,tas) %>% unique()
    embs <- embbedings %>% select(-cell,-cmap_name,-duplIdentifier,-pert_id,-pert_dose,-pert_itime,-tas) %>% unique()
  }
  rownames(embs) <- NULL
  embs  <-  embs %>% column_to_rownames('sig_id')
  pca_all <- prcomp(embs,scale = scale)
  df_pca <- data.frame(pca_all$x[,1:dim])
  rownames(df_pca) <- rownames(embs)
  col_names <- paste0(rep('PC',dim),seq(1,dim))
  colnames(df_pca) <- col_names
  embs_reduced <- df_pca %>% rownames_to_column('sig_id')
  if ('moa' %in% colnames(embbedings)){
    embs_reduced <- suppressWarnings(left_join(embs_reduced,
                                               sample_info %>% select(sig_id,cmap_name,cell,moa,pert_dose,pert_itime,tas) %>% 
                                                 unique()))
  }else{
    embs_reduced <- suppressWarnings(left_join(embs_reduced,
                                               sample_info %>% select(sig_id,cmap_name,cell,pert_dose,pert_itime,tas) %>% 
                                                 unique()))
  }
  if (visualize=='moa'){
    embs_reduced <- embs_reduced %>% group_by(sig_id) %>% mutate(nn=n_distinct(moa)) %>% ungroup()
    embs_reduced <- embs_reduced %>% mutate(keep = ifelse(nn>1 & moa=='other',FALSE,TRUE)) %>% 
      filter(keep==TRUE) %>% select(-keep) %>% unique()
    embs_reduced <- embs_reduced %>% filter(nn==1) %>% select(-nn) %>% unique()
  }else if (visualize=='cmap_name'){
    embs_reduced <- embs_reduced %>% select(sig_id,cmap_name,all_of(col_names)) %>% unique()
    embs_reduced <- embs_reduced %>% group_by(cmap_name) %>% mutate(no_sigs = ifelse(is.na(cmap_name),-666,n_distinct(sig_id))) %>% ungroup()
    top <- embs_reduced %>% select(cmap_name,no_sigs) %>% unique() %>% arrange(-no_sigs)
    top <- top[1:top_drugs,]
    top <- top$cmap_name
    embs_reduced <- embs_reduced %>% mutate(cmap_name=ifelse(cmap_name %in% top,cmap_name,'other'))
    col_breaks <- c(top,'other')
  }
  
  if (dim==2){
    embs_reduced <- embs_reduced %>% select(all_of(c(col_names,visualize)))
    colnames(embs_reduced)[dim+1] <- 'group'
    if (visualize %in% c('moa','target','cmap_name')){
      pca_plot <- ggplot(embs_reduced,aes(PC1,PC2)) +geom_point(aes(col=group,size=group))+
        scale_color_manual(values = colors,breaks = col_breaks)+
        scale_size_manual(values = c(rep(size_points,length(colors)-1),0.25),breaks = col_breaks)+
        ggtitle(title) + 
        xlab(paste0('PC1'))+ ylab(paste0('PC2'))+theme_minimal()+
        theme(text = element_text(family = 'Arial',size=14),plot.title = title_pos,
              legend.text=element_text(size=14),legend.position = 'top')
    }else{
      pca_plot <- ggplot(embs_reduced,aes(PC1,PC2)) +geom_point(aes(col=group))+
        ggtitle(title) + 
        xlab(paste0('PC1'))+ ylab(paste0('PC2'))+theme_minimal()+
        theme(text = element_text(family = 'Arial',size=14),plot.title = title_pos,
              legend.text=element_text(size=14),legend.position = 'top')
    }
  }else{
    embs_reduced <- embs_reduced %>% select(all_of(c(col_names,visualize)))
    colnames(embs_reduced)[dim+1] <- 'group'
    if (visualize %in% c('moa','target','cmap_name')){
      pca_plot <- ggplot(embs_reduced,aes(x=PC1,y=PC2,z=PC3,col=group))+
        ggtitle(title) +
        scale_color_manual(values = colors,breaks = col_breaks)+
        scale_size_manual(values = c(rep(size_points,length(colors)-1),0.25),breaks = col_breaks)+
        theme_void() +
        labs_3D(labs=c("PC1", "PC2", "PC3"),
                angle=c(0,0,0),
                hjust=c(0,2,2),
                vjust=c(2,2,-1))+
        axes_3D(phi=30) +
        stat_3D()+
        theme(text = element_text(family = 'Arial',size=14),plot.title = title_pos,
              legend.text=element_text(size=14),legend.position = 'top')
    }else{
      pca_plot <- ggplot(embs_reduced,aes(x=PC1,y=PC2,z=PC3,col=group))+
        ggtitle(title) +
        theme_void() +
        labs_3D(labs=c("PC1", "PC2", "PC3"),
                angle=c(0,0,0),
                hjust=c(0,2,2),
                vjust=c(2,2,-1))+
        axes_3D(phi=30) +
        stat_3D()+
        theme(text = element_text(family = 'Arial',size=14),plot.title = title_pos,
              legend.text=element_text(size=14),legend.position = 'top')
    }
  }
  if (visualize=='tas'){
    pca_plot <- pca_plot + scale_color_gradient(high = 'red',low='white',limits=c(min(embs_reduced$group)-0.03,max(embs_reduced$group)+0.01))+
      theme(legend.position = 'right')
    if (dim==2){
      pca_plot_binned <- ggplot(embs_reduced,aes(PC1,PC2)) +
        stat_density_2d(geom="polygon",
                        aes(fill=cut(group,
                                     breaks = c(0.3,0.4,0.5,0.6,0.7,0.8,0.9,1),
                                     labels = c("0.3-0.4","0.4-0.5","0.5-0.6","0.6-0.7",
                                                '0.7-0.8',"0.8-0.9","0.9-1")))) + labs(fill='tas binned')+
      ggtitle(title) +
        xlab(paste0('PC1'))+ ylab(paste0('PC2'))+theme_minimal()+
        theme(text = element_text(family = 'Arial',size=14),plot.title = title_pos,
              legend.text=element_text(size=14),legend.position = 'right')
      # pca_plot_binned <- ggplot(embs_reduced,aes(PC1,PC2)) +
      #   geom_point(aes(col=cut(group, 
      #                          breaks = c(0.3,0.4,0.5,0.6,0.7,0.8,0.9,1), 
      #                          labels = c("0.3-0.4","0.4-0.5","0.5-0.6","0.6-0.7",
      #                                     '0.7-0.8',"0.8-0.9","0.9-1")))) + 
      #   labs(fill='tas binned')+
      #   ggtitle(title) + 
      #   xlab(paste0('PC1'))+ ylab(paste0('PC2'))+theme_minimal()+
      #   theme(text = element_text(family = 'Arial',size=14),plot.title = title_pos,
      #         legend.text=element_text(size=14),legend.position = 'right')
    }
  }
  if (visualize=='pert_dose'){
    pca_plot <- pca_plot + scale_color_gradient(trans = "log10",high = 'red',low='white',
                                                limits=c(min(embs_reduced$group)-0.03,max(embs_reduced$group)+0.01))+
      theme(legend.position = 'right')
  }
  pca_plot <- pca_plot + labs(color = visualize) + guides(shape = "none", size = "none",alpha="none")
  if (visualize=='tas'){
    pca_plot_binned <- pca_plot_binned + labs(color = visualize) + guides(shape = "none", size = "none",alpha="none")
    pca_plot <- list(pca_plot,pca_plot_binned)
  }
  if (show_plot==T){
    print(pca_plot)
  }
  return(pca_plot)
}
tsne_visualize <- function(embbedings,
                           normalize=F,
                           init_dim= 10,
                           iter= 1000,
                           dim=2,
                           scale=F,
                           visualize = 'cmap_name',
                           top_drugs = 7,
                           show_plot=F,
                           title=NULL,
                           title_pos = element_blank(),
                           colors=NULL,
                           col_breaks=NULL,
                           size_points = 2,
                           verbose=F){
  if ('moa' %in% colnames(embbedings)){
    sample_info <- embbedings %>% select(sig_id,cmap_name,pert_id,cell,moa,drugs_per_moa,pert_dose,pert_itime,tas) %>% unique()
    embs <- embbedings %>% select(-cell,-cmap_name,-duplIdentifier,-moa,-pert_id,-drugs_per_moa,-pert_dose,-pert_itime,-tas) %>% unique()
  }else{
    sample_info <- embbedings %>% select(sig_id,cmap_name,pert_id,cell,pert_dose,pert_itime,tas) %>% unique()
    embs <- embbedings %>% select(-cell,-cmap_name,-duplIdentifier,-pert_id,-pert_dose,-pert_itime,-tas) %>% unique()
  }
  rownames(embs) <- NULL
  embs  <-  embs %>% column_to_rownames('sig_id')
  
  library(Rtsne)
  perpl = DescTools::RoundTo(sqrt(nrow(embs)), multiple = 5, FUN = round)
  emb_size = ncol(embs)
  set.seed(42)
  tsne_all <- Rtsne(embs, 
                    dims = dim, perplexity=perpl, 
                    verbose=verbose, max_iter = iter,initial_dims = init_dim,check_duplicates = T,
                    normalize = normalize,pca_scale = scale,
                    num_threads = 15)
  if (dim==2){
    df_tsne <- data.frame(V1 = tsne_all$Y[,1], V2 =tsne_all$Y[,2])
  }else{
    df_tsne <- data.frame(V1 = tsne_all$Y[,1], V2 =tsne_all$Y[,2],V3 =tsne_all$Y[,3])
  }
  rownames(df_tsne) <- rownames(embs)
  col_names <- paste0(rep('tSNE-',dim),seq(1,dim))
  colnames(df_tsne) <- col_names
  embs_reduced <- df_tsne %>% rownames_to_column('sig_id')
  if ('moa' %in% colnames(embbedings)){
    embs_reduced <- suppressWarnings(left_join(embs_reduced,
                                               sample_info %>% select(sig_id,cmap_name,cell,moa,pert_dose,pert_itime,tas) %>% 
                                                 unique()))
  }else{
    embs_reduced <- suppressWarnings(left_join(embs_reduced,
                                               sample_info %>% select(sig_id,cmap_name,cell,pert_dose,pert_itime,tas) %>% 
                                                 unique()))
  }
  if (visualize=='moa'){
    embs_reduced <- embs_reduced %>% group_by(sig_id) %>% mutate(nn=n_distinct(moa)) %>% ungroup()
    embs_reduced <- embs_reduced %>% mutate(keep = ifelse(nn>1 & moa=='other',FALSE,TRUE)) %>% 
      filter(keep==TRUE) %>% select(-keep) %>% unique()
    embs_reduced <- embs_reduced %>% filter(nn==1) %>% select(-nn) %>% unique()
  }else if (visualize=='cmap_name'){
    embs_reduced <- embs_reduced %>% select(sig_id,cmap_name,all_of(col_names)) %>% unique()
    embs_reduced <- embs_reduced %>% group_by(cmap_name) %>% mutate(no_sigs = ifelse(is.na(cmap_name),-666,n_distinct(sig_id))) %>% ungroup()
    top <- embs_reduced %>% select(cmap_name,no_sigs) %>% unique() %>% arrange(-no_sigs)
    top <- top[1:top_drugs,]
    top <- top$cmap_name
    embs_reduced <- embs_reduced %>% mutate(cmap_name=ifelse(cmap_name %in% top,cmap_name,'other'))
    col_breaks <- c(top,'other')
  }
  
  if (dim==2){
    embs_reduced <- embs_reduced %>% select(all_of(c(col_names,visualize)))
    colnames(embs_reduced)[dim+1] <- 'group'
    if (visualize %in% c('moa','target','cmap_name')){
      tsne_plot <- ggplot(embs_reduced,aes(`tSNE-1`,`tSNE-2`)) +geom_point(aes(col=group,size=group))+
        scale_color_manual(values = colors,breaks = col_breaks)+
        scale_size_manual(values = c(rep(size_points,length(colors)-1),0.25),breaks = col_breaks)+
        ggtitle(title) + 
        xlab(paste0('tSNE-1'))+ ylab(paste0('tSNE-2'))+theme_minimal()+
        theme(text = element_text(family = 'Arial',size=14),plot.title = title_pos,
              legend.text=element_text(size=14),legend.position = 'top')
    }else{
      tsne_plot <- ggplot(embs_reduced,aes(`tSNE-1`,`tSNE-2`)) +geom_point(aes(col=group))+
        ggtitle(title) + 
        xlab(paste0('tSNE-1'))+ ylab(paste0('tSNE-2'))+theme_minimal()+
        theme(text = element_text(family = 'Arial',size=14),plot.title = title_pos,
              legend.text=element_text(size=14),legend.position = 'top')
    }
    tsne_plot <- tsne_plot + labs(color = visualize)
  }else{
    embs_reduced <- embs_reduced %>% select(all_of(c(col_names,visualize)))
    colnames(embs_reduced)[dim+1] <- 'group'
    if (visualize %in% c('moa','target','cmap_name')){
      tsne_plot <- ggplot(embs_reduced,aes(x=`tSNE-1`,y=`tSNE-2`,z=`tSNE-3`,col=group))+
        ggtitle(title) +
        scale_color_manual(values = colors,breaks = col_breaks)+
        scale_size_manual(values = c(rep(size_points,length(colors)-1),0.25),breaks = col_breaks)+
        theme_void() +
        labs_3D(labs=c("tSNE-1", "tSNE-2", "tSNE-3"),
                angle=c(0,0,0),
                hjust=c(0,2,2),
                vjust=c(2,2,-1))+
        axes_3D(phi=30) +
        stat_3D()+
        theme(text = element_text(family = 'Arial',size=14),plot.title = title_pos,
              legend.text=element_text(size=14),legend.position = 'top')
    }else{
      tsne_plot <- ggplot(embs_reduced,aes(x=`tSNE-1`,y=`tSNE-2`,z=`tSNE-3`,col=group))+
        ggtitle(title) +
        theme_void() +
        labs_3D(labs=c("tSNE-1", "tSNE-2", "tSNE-3"),
                angle=c(0,0,0),
                hjust=c(0,2,2),
                vjust=c(2,2,-1))+
        axes_3D(phi=30) +
        stat_3D()+
        theme(text = element_text(family = 'Arial',size=14),plot.title = title_pos,
              legend.text=element_text(size=14),legend.position = 'top')
    }
  }
  if (visualize=='tas'){
    tsne_plot <- ggplot(embs_reduced,aes(`tSNE-1`,`tSNE-2`)) +
      geom_point(aes(col=cut(group, 
                             breaks = c(0.3,0.4,0.6,1), 
                             labels = c("0.3-0.4","0.4-0.6","0.6-1")))) + 
      labs(fill='tas binned')+
      ggtitle(title) + 
      xlab(paste0('tSNE-1'))+ ylab(paste0('tSNE-2'))+theme_minimal()+
      theme(text = element_text(family = 'Arial',size=14),plot.title = title_pos,
            legend.text=element_text(size=14),legend.position = 'right')
  }
  if (visualize=='pert_dose'){
    tsne_plot <- tsne_plot + scale_color_gradient(trans = "log10",high = 'red',low='white',
                                                limits=c(min(embs_reduced$group)-0.03,max(embs_reduced$group)+0.01))+
      theme(legend.position = 'right')
  }
  tsne_plot <- tsne_plot + labs(color = visualize)+ guides(shape = "none", size = "none",alpha="none")
  if (show_plot==T){
    print(tsne_plot)
  }
  return(tsne_plot)
}

### Load data---------------------------------------------------
sigInfo <- read.delim('../../../L1000_2021_11_23/siginfo_beta.txt')
sigInfo <- sigInfo %>% mutate(quality_replicates = ifelse(is_exemplar_sig==1 & qc_pass==1 & nsample>=3,1,0))
sigInfo <- sigInfo %>% filter(pert_type=='trt_cp')
sigInfo <- sigInfo %>% filter(quality_replicates==1)
# Filter based on TAS
sigInfo <- sigInfo %>% filter(tas>=0.3)
# Duplicate information
sigInfo <- sigInfo %>% mutate(duplIdentifier = paste0(cmap_name,"_",pert_idose,"_",pert_itime,"_",cell_iname))
sigInfo <- sigInfo %>% group_by(duplIdentifier) %>% mutate(dupl_counts = n()) %>% ungroup()
# Drug condition information
sigInfo <- sigInfo  %>% mutate(conditionId = paste0(cmap_name,"_",pert_idose,"_",pert_itime))

# Load drug information (Targets,MoA etc)
# drugInfo <- read.delim('../../../L1000_2021_11_23/compoundinfo_beta.txt')
# drugInfo <- drugInfo %>% group_by(moa) %>% mutate(drugs_per_moa=n_distinct(pert_id)) %>% ungroup() %>% 
#   mutate(drugs_per_moa = ifelse(moa=='' | moa==' ' | moa=='  ' | is.na(moa) | is.null(moa),-666,drugs_per_moa))
# drugInfo <- drugInfo %>% group_by(target) %>% mutate(drugs_per_target = n_distinct(pert_id)) %>% ungroup() %>%
#   mutate(drugs_per_target = ifelse(target=='' | target==' ' | target=='  ' | is.na(target) | is.null(target),-666,drugs_per_target))
# custom_keep_moa <- c('MTOR inhibitor','MTOR inhibitor','Estrogen receptor agonist','PI3K inhibitor')
# drugInfo <- drugInfo %>% unique()
# drugInfo <- drugInfo %>% select(-inchi_key,-canonical_smiles)
# drugInfo <- drugInfo %>% unique()
# sigInfo <- left_join(sigInfo,drugInfo)
# sigInfo <- sigInfo %>% filter(!is.na(moa) | !is.na(target))
# sigInfo <- sigInfo %>% filter(!is.null(moa) | !is.null(target))
# sigInfo <- sigInfo %>% filter(moa!='' | target!='')
# sigInfo <- sigInfo %>% filter(moa!=' ' | target!=' ')
# sigInfo <- sigInfo %>% filter(moa!='  ' | target!='  ')
# sigInfo <- sigInfo %>% unique()
# sigInfo <- sigInfo %>% select(-drugs_per_moa,-drugs_per_target)

# Load embeddings and visualize drug space-------------------------------
emb1 <- distinct(data.table::fread('../results/trained_embs_all/AllEmbs_MI_pc3_withclass.csv',header = T)) %>% column_to_rownames('V1')
emb1 <- emb1 %>% mutate(cell='PC3')
emb2 <- distinct(data.table::fread('../results/trained_embs_all/AllEmbs_MI_ha1e_withclass.csv',header = T)) %>% column_to_rownames('V1')
emb2 <- emb2 %>% mutate(cell='HA1E')
all_embs <- rbind(emb1,emb2)
all_embs_proc <- left_join(all_embs %>% rownames_to_column('sig_id'),
                           sigInfo %>% select(sig_id,pert_id,cmap_name,duplIdentifier,pert_dose,pert_itime,tas) %>% unique())
# all_embs_proc <- all_embs_proc %>% group_by(moa) %>% mutate(drugs_per_moa=n_distinct(pert_id)) %>% ungroup() %>% 
#   mutate(drugs_per_moa = ifelse(moa=='other' | moa=='' | moa==' ' | moa=='  ' | is.na(moa) | is.null(moa),-666,drugs_per_moa))
# all_embs_proc <- all_embs_proc  %>% 
#   mutate(moa = ifelse(drugs_per_moa>=20 | moa %in% custom_keep_moa,moa,'other'))

#pca_samples <- prcomp(all_embs_proc[,2:1025],center = T,scale = F)

### visualize drugs first-----------------------------
display.brewer.all(n = 12, type = "all", select = NULL,
                   colorblindFriendly = TRUE)
colors <- brewer.pal(n = 12, name = "Paired")
colors <- c(colors,"#D3D3D3")
colors[length(colors)-2] <- "black"

p <- tsne_visualize(all_embs_proc,
              dim=2,
              show_plot=T,
              colors=colors,
              col_breaks=uniq_moas,
              visualize = 'cmap_name',
              top_drugs = 12,
              size_points = 2,
              verbose = T)
p <- p + labs(color='drug')
print(p)
ggsave('../article_supplementary_info/drugs_pc3_ha1e_tsne_all.png',
       plot=p,
       width = 9,
       height = 9,
       units = 'in',
       dpi=600)
postscript('../article_supplementary_info/drugs_pc3_ha1e_tsne_all.eps',width = 9,height = 9)
print(p)
dev.off()

### Visualize tas---------------------------------------
p_pca <- pca_visualize(all_embs_proc,
                   dim=2,
                   show_plot=T,
                   scale = F,
                   visualize = 'tas',
                   verbose = T)
p_pca <- (p_pca[[1]] + xlim(c(-5,5))) + (p_pca[[2]]) #there are a few outliers making it hard to visualize
print(p_pca)
ggsave('../article_supplementary_info/tas_pc3_ha1e_pca_all.png',
       plot=p_pca,
       width = 9,
       height = 9,
       units = 'in',
       dpi=600)
ggsave('../article_supplementary_info/tas_pc3_ha1e_pca_all.eps',
       plot=p_pca,
       device = cairo_ps,
       width = 9,
       height = 9,
       units = 'in',
       dpi=600)
# p_tsne <- tsne_visualize(all_embs_proc,
#                        dim=2,
#                        show_plot=T,
#                        scale = F,
#                        visualize = 'tas',
#                        verbose = T)
# print(p_tsne)
# ggsave('../article_supplementary_info/tas_pc3_ha1e_tsne_all.png',
#        plot=p_tsne,
#        width = 9,
#        height = 9,
#        units = 'in',
#        dpi=600)
# postscript('../article_supplementary_info/tas_pc3_ha1e_tsne_all.eps',width=9,height = 9)
# print(p_tsne)
# dev.off()

### Visualize time---------------------------------------
p <- tsne_visualize(all_embs_proc,
                       dim=2,
                       show_plot=T,
                       scale = T,
                       visualize = 'pert_itime',
                       verbose = T)
ggsave('../article_supplementary_info/time_pc3_ha1e_tsne_all.png',
       plot=p,
       width = 9,
       height = 9,
       units = 'in',
       dpi=600)
postscript('../article_supplementary_info/time_pc3_ha1e_tsne_all.eps',width = 9,height = 9)
print(p)
dev.off()

# ### Visualize moa-------------------------------
# uniq_moas <- unique(all_embs_proc$moa)
# uniq_moas <- uniq_moas[which(uniq_moas!='other')]
# uniq_moas <- c(uniq_moas,'other')
# colors <- brewer.pal(n = length(uniq_moas), name = "Paired")
# p <- tsne_visualize(all_embs_proc,
#                     dim=2,
#                     show_plot=T,
#                     colors=colors,
#                     col_breaks=uniq_moas,
#                     visualize = 'moa',
#                     size_points = 2.5,
#                     alpha_points = 1,
#                     verbose = T)

### Distance separation in the latent space--------------------------------------------
emb1 <- distinct(data.table::fread('../results/trained_embs_all/AllEmbs_MI_pc3_withclass.csv',header = T)) %>% column_to_rownames('V1')
emb1 <- emb1 %>% mutate(cell='PC3')
emb2 <- distinct(data.table::fread('../results/trained_embs_all/AllEmbs_MI_ha1e_withclass.csv',header = T)) %>% column_to_rownames('V1')
emb2 <- emb2 %>% mutate(cell='HA1E')
all_embs <- rbind(emb1,emb2)

### Calculate pairwise distances
all_embs_proc <- left_join(all_embs %>% rownames_to_column('sig_id'),
                           sigInfo %>% select(sig_id,cmap_name) %>% unique())

mat <- all_embs_proc %>% column_to_rownames('sig_id') %>%
  select(-cmap_name,-cell)
mat <- t(mat)
dist <- 1 - suppressMessages(cosine(mat))
# Convert to long format data frame
# Keep only unique (non-self) pairs
dist[lower.tri(dist,diag = T)] <- NA
dist <- reshape2::melt(dist)
dist <- dist %>% filter(!is.na(value))
# Merge meta-data info and distances values
dist <- suppressMessages(left_join(dist,sigInfo %>% select(sig_id,cmap_name) %>% unique(),by = c("Var1"="sig_id")))
dist <- suppressMessages(left_join(dist,sigInfo %>% select(sig_id,cmap_name) %>% unique(),by = c("Var2"="sig_id")))
dist <- dist %>% filter(!is.na(value))
dist <- dist %>% mutate(is_same = (cmap_name.x==cmap_name.y))
dist <-dist %>% mutate(is_same=ifelse(is_same==T,
                                      'Same drug','Random Signatures')) %>%
  mutate(is_same = factor(is_same,
                          levels = c('Random Signatures',
                                     'Same drug')))

eff_ssize <- effectsize::cohens_d(as.matrix(dist %>% filter(is_same!="Same drug") %>% select(value)),
                                  as.matrix(dist %>% filter(is_same=="Same drug") %>% select(value)),
                                  ci=0.95)

### Visualize
p <- ggplot(dist, aes(x=is_same, y=value, fill = is_same)) +
  geom_violin(position = position_dodge(width = 1),width = 1)+geom_boxplot(position = position_dodge(width = 1),width = 0.05,
                                                                           size=1,outlier.shape = NA)+
  scale_fill_discrete(name="Latent embeddings` distance distributions",
                      labels=c("Random Signatures","Same drug"))+
  ylim(0,2)+
  xlab("pairwise relationship")+ylab("Cosine Distance")+
  annotate('text',x=1.5,y=1.3,label=paste0('Cohen`s d = ',round(eff_ssize$Cohens_d,2)),
           size=5,fontface='bold') +
  theme_minimal(base_family = "Arial",base_size = 30) +
  theme(text = element_text(family = "Arial",size = 30),
        axis.ticks.x=element_blank(),
        axis.text = element_text(family = "Arial",face = 'bold'),
        axis.text.x =element_text(family = "Arial",face = 'bold',size=28),
        legend.position = "none")

print(p)
ggsave('../article_supplementary_info/drugs_distance_separ_ha1e_pc3.eps',
       plot = p,
       device = cairo_ps,
       height = 9,
       width = 9,
       units = 'in',
       dpi=600)
