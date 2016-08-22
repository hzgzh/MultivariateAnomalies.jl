# __precompile__(true)

module MultivariateAnomalies
#######################
  using MultivariateStats
  using Distances
  using LIBSVM
  using Base.Cartesian

  # DistDensity
  export
    dist_matrix,
    dist_matrix!,
    init_dist_matrix,
    knn_dists,
    init_knn_dists,
    knn_dists!,
    kernel_matrix,
    kernel_matrix!,
# Detection Algorithms
    REC,
    init_REC,
    REC!,
    KDE,
    init_KDE,
    KDE!,
    init_T2,
    T2,
    T2!,
    KNN_Gamma,
    init_KNN_Gamma,
    KNN_Gamma!,
    KNN_Delta,
    KNN_Delta!,
    init_KNN_Delta,
    UNIV,
    UNIV!,
    init_UNIV,
    SVDD_train,
    SVDD_predict,
    SVDD_predict!,
    init_SVDD_predict,
    KNFST_predict,
    KNFST_predict!,
    init_KNFST,
# FeatureExtraction
    sMSC,
    globalPCA,
    globalICA,
    TDE,
    mw_VAR,
    mw_COR,
    EWMA,
    EWMA!,
    get_MedianCycles,
    get_MedianCycle,
    get_MedianCycle!,
    init_MedianCycle,
# AUC
    auc,
    auc_fpr_tpr,
    boolevents,
# Scores
    get_quantile_scores,
    compute_ensemble

# Distance and Density Estimation
include("DistDensity.jl")
# Multivariate Anomaly Detection Algorithms
include("DetectionAlgorithms.jl")
include("KNFST.jl")
# AUC computations
include("AUC.jl")
# Feature Extraction techniques
include("FeatureExtraction.jl")
# post processing for Anomaly Scores
include("Scores.jl")

#######################
end
