# Load necessary libraries
library(phyloseq)
library(ggplot2)
library(magrittr)
library(dplyr)

# Load the ASV and taxonomy data
asv_data <- read.csv("ASV.csv",row.names = 1)
asv_data <- asv_data[-106,] #remove negative control
taxonomy_data <- read.csv("taxa.csv",row.names = 1)
sample_data <- sample_data(read.csv("merge.csv",row.names = 1))
sample_data <- na.omit(sample_data)
time <- as.factor(sample_data$time.day.)
asv_data <- asv_data[match(rownames(sample_data),rownames(asv_data)),]

# Convert taxonomy data to matrix and specify column names for Phyloseq
taxonomy_matrix <- as.matrix(taxonomy_data)
colnames(taxonomy_matrix) <- c("Kingdom", "Phylum", "Class", "Order", "Family", "Genus", "Species")

# create phyloseq objects
otu_table <- otu_table(as.matrix(asv_data), taxa_are_rows = FALSE)
tax.table <- tax_table(taxonomy_matrix)
  
physeq <- phyloseq(otu_table,tax.table,sample_data)
t.genus <- tax_glom(physeq, taxrank = "Genus") # agglomerate genus
# find top 10 abundence genus
top10 <- names(sort(taxa_sums(t.genus),decreasing = TRUE))[1:10]
t.genus.prop <- transform_sample_counts(t.genus,function(x) x/sum(x))
t.genus.prop.top10 <- prune_taxa(top10,t.genus.prop)
## plot
t.genus.prop.top10@sam_data$time.day. <- factor(t.genus.prop.top10@sam_data$time.day.)
t.genus.prop.top10@sam_data <- t.genus.prop.top10@sam_data[order(t.genus.prop.top10@sam_data$time.day.)]
t.genus.prop.top10@otu_table <- t.genus.prop.top10@otu_table[match(rownames(t.genus.prop.top10@sam_data),rownames(t.genus.prop.top10@otu_table)),]

abudence_plot <- t.genus.prop.top10 %>%
  subset_samples(treatment %in% c("control","Nisin","Pediocin","Divergicin","MicrocinJ25")) %>% #"Nisin","Pediocin","Divergicin","MicrocinJ25"
  plot_bar(fill = "Genus") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5)) +
  #facet_grid(~treatment) +
  geom_bar(aes(),stat = "identity",position = "stack") +
  theme_classic() +
  coord_flip()
  labs(title = "relative abudence of top 10 genus", 
       x = "samples", y = "relative abundence")

abudence_plot$data$Sample <- factor(abudence_plot$data$Sample,
                                    levels = rownames(sample_data),
                                    ordered = TRUE)
print(abudence_plot)
  dev.off()

# Calculate Chao1 diversity
bacterocin_exp <- subset_samples(physeq, 
                                 treatment %in% c("control","Nisin","Pediocin","Divergicin","MicrocinJ25"))
chao1_diversity <- estimate_richness(bacterocin_exp, measures = "Chao1")

# Add sample names as a column
chao1_diversity$Sample <- rownames(chao1_diversity)
chao1_diversity$treatment <- bacterocin_exp@sam_data$treatment

# Plot Chao1 diversity
chao1_plot <- ggplot(chao1_diversity, aes(x = Sample, y = Chao1, fill = treatment)) +
  geom_bar(stat = "identity")+
  theme_minimal() +
  xlab("Sample") +
  ylab("Chao1 Diversity Index") +
  coord_flip() +
  ggtitle("Chao1 Diversity Across Samples")

chao1_plot$data$Sample <- factor(chao1_plot$data$Sample,levels = chao1_plot$data$Sample,
                                 ordered = TRUE)
print(chao1_plot)
# Calculate Shannon diversity
shannon_diversity <- estimate_richness(bacterocin_exp, measures = "Shannon")

# Add sample names as a column
shannon_diversity$Sample <- rownames(shannon_diversity)
shannon_diversity$treatment <- bacterocin_exp@sam_data$treatment

# Plot Shannon diversity
shannon_plot <- ggplot(shannon_diversity, aes(x = Sample, y = Shannon, fill = treatment)) +
  coord_flip() +
  geom_bar(stat = "identity") +
  theme_minimal() +
  xlab("Sample") +
  ylab("Shannon Diversity Index") +
  ggtitle("Shannon Diversity Across Samples") +
  theme(axis.text.x = element_text(angle = 90, hjust = 1))# Adjust text angle for better readability if necessary

shannon_plot$data$Sample <- factor(shannon_plot$data$Sample,levels = shannon_plot$data$Sample,
                                   ordered = TRUE)
print(shannon_plot)
# Calculate Simpson diversity
simpson_diversity <- estimate_richness(bacterocin_exp, measures = "Simpson")

# Add sample names as a column
simpson_diversity$Sample <- rownames(simpson_diversity)
simpson_diversity$treatment <- bacterocin_exp@sam_data$treatment
# Plot Simpson diversity
simpson_diversity_plot <- 
  ggplot(simpson_diversity, aes(x = Sample, y = Simpson, fill = treatment)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  theme_minimal() +
  xlab("Sample") +
  ylab("Simpson Diversity Index") +
  ggtitle("Simpson Diversity Across Samples") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) 

simpson_diversity_plot$data$Sample <-  factor(simpson_diversity_plot$data$Sample,
                                              levels = simpson_diversity_plot$data$Sample,
                                              ordered = TRUE)

print(simpson_diversity_plot)
# Adjust text angle for better readability if necessary

# Assuming 'physeq' is your phyloseq object
chao1_diversity <- estimate_richness(bacterocin_exp, measures = "Chao1")
shannon_diversity <- estimate_richness(bacterocin_exp, measures = "Shannon")
simpson_diversity <- estimate_richness(bacterocin_exp, measures = "Simpson")
observed_diversity <- estimate_richness(bacterocin_exp, measures = "Observed")

# Combine all indices into one data frame
combined_indices <- data.frame(Sample = rownames(chao1_diversity),
                               Chao1 = chao1_diversity$Chao1,
                               Shannon = shannon_diversity$Shannon,
                               Simpson = simpson_diversity$Simpson)
# View the head of the combined table
head(combined_indices)

# Export the combined table to a CSV file
write.csv(combined_indices, "combined_diversity_indices.csv", row.names = FALSE)

