### ML Pipeline Mindmap

```mermaid
%%{init: {'theme': 'base', 'flowchart': {'nodeSpacing': 60, 'rankSpacing': 80, 'diagramPadding': 20}, 'sequence': {'actorMargin': 80, 'messageMargin': 40}, 'themeVariables': {'primaryColor': '#BBDEFB', 'primaryTextColor': '#212121', 'primaryBorderColor': '#1565C0', 'lineColor': '#64B5F6', 'secondaryColor': '#F8BBD0', 'secondaryTextColor': '#212121', 'secondaryBorderColor': '#AD1457', 'tertiaryColor': '#C8E6C9', 'tertiaryTextColor': '#212121', 'tertiaryBorderColor': '#2E7D32', 'noteBkgColor': '#FFF9C4', 'noteTextColor': '#212121', 'noteBorderColor': '#F9A825', 'fontFamily': 'Inter, Roboto, sans-serif', 'fontSize': '14px'}}}%%
mindmap
  root((ML Pipeline))
    Data
      Collection
        APIs
        Scraping
        Surveys
      Cleaning
        Deduplication
        Imputation
        Normalization
      Feature Engineering
        Encoding
        Scaling
        Selection
    Modeling
      Experimentation
        Baseline
        Hyperparameter Tuning
      Training
        Distributed Training
        Checkpointing
      Evaluation
        Metrics
        Cross Validation
        Bias Analysis
    Deployment
      Serving
        REST API
        Batch Inference
      Monitoring
        Data Drift
        Performance Degradation
      Retraining
        Scheduled
        Trigger Based
    Infrastructure
      Compute
        GPU Clusters
        Spot Instances
      Storage
        Feature Store
        Model Registry
      Orchestration
        Airflow
        Kubeflow
```

Four main branches cover the full ML lifecycle: Data (collection through feature engineering), Modeling (experimentation through evaluation), Deployment (serving through retraining), and Infrastructure (compute, storage, orchestration). Hierarchy is 4 levels deep. No custom styling applied — mindmap relies on the theme init block for colors.
