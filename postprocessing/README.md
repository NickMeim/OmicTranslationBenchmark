## Post-processing of embeddings and model's results.
1. CompareCohenD.R: Compare the latent space separation, based on Cohen's d, of different approaches (Supplementary Figure 30)
2. EncodedControlsAnalysis.R: Visualize in 2D the embeddings of controls, ccle, and the trained covariates (Figure 3f-3g)
3. GenesetsPerformance.R: Evaluate the performance in calculating gene set enrichment based on the predicted values from the model (Supplementary Figure 7)
4. LatentSpaceSeparation.R: Generate plots for estimating latent space embeddings separation (Figure 3a-3e)
5. PerformanceAnalysis.R: Script to perform the analysis and generate the panels for Figure 2.
6. SimilarityOfTrainValSets.R: Script to generate Supplementary Figure 12 and estimate the similarity of train and validation set, to make sure there is no leakage of information when evaluating models.
7. enrichment_calculations.R: Function to perform gene set enrichment for different types of genesets: KEGG pathways, GO Terms, MSIG genesets, even TFs but by using GSEA.
8. getRanksImportant.R: Script to perform analysis of genes importance for Figure 4.
9. DrugMoALatentSpaceAnalysis.R: Script to visualize and analyze the properties of the latent space with regards to drugs and their MoA.
10. GlobalityComparison.R: Script to evaluate the globality of the latent space.
11. LatentDimPerformanceAnalysis.R: Script to evaluate the performance of the model as a function of the dimension of the latent space.
12. MIVisualization.R: Script to evaluate and visualize the effecs of prior loss and sidtribution of the latent embeddings on Mutual Information (MI).
13. priorLossPerformance.R: Script to evaluate performance as a function of the prior distribution constraint.
14. SameCellImputationFunctionalAnalysis.R: Script to evaluate inferred TFs or other genesets, after imputing gene expression in the same cell line using the model.
15. SameCellImputationPerformance.R: Script to evaluate performance in the case of imputing gene expression in the same cell line using the model.

