# bulkrna-Bioc-stage1（中间镜像）：在 bulkrna-base:V1.1.1 上固定 ggplot2 3.5.2、源码 magick 与 Bioconductor 3.20 DE/GSVA/热图核心栈。
# 完整 bulk-bioc + survival 需再构建 bulkrna-Bioc（基于本镜像）。父镜像默认见 BASE_IMAGE。
#
# bulkrna-base 已含 gfortran、BiocManager 与 ggplot2 4.x；装 Bioc 前必须将 ggplot2 钉为 3.5.2（clusterProfiler/ggtree 见终镜像说明）。
#
# 构建示例：
#   cd /home/ubuntu/zhaoyiran/TOOL-Dockerfile/bulkRNA/bulkrna-Bioc-stage1 && docker build -t quay.io/1733295510/bulkrna-bioc-stage1:V1.0.1 .

ARG BASE_IMAGE=quay.io/1733295510/bulkrna-base:V1.1.1
FROM ${BASE_IMAGE}

LABEL maintainer="1733295510 <1733295510@qq.com>"
LABEL org.opencontainers.image.title="bulkRNA-Bioc-stage1"
LABEL org.opencontainers.image.description="Intermediate: ggplot2 3.5.2 + magick + Bioc 3.20 core (DESeq2, limma, GSVA, ComplexHeatmap, org.Hs.eg.db). No clusterProfiler / MsigDB / survival stack."

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

ARG R_INSTALL_NCPUS=4
ENV R_INSTALL_NCPUS=${R_INSTALL_NCPUS}

USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    libmagick++-6.q16-dev \
    libmagickcore-6.q16-dev \
    libmagickwand-6.q16-dev \
 && rm -rf /var/lib/apt/lists/*

# ggplot2 3.5.2 + magick（与 bulkrna-Bioc 原单阶段一致；magick 用 Ncpus=1 降内存峰值）
RUN R -e "nc <- suppressWarnings(as.integer(Sys.getenv('R_INSTALL_NCPUS', '4'))); \
  nc <- if (is.na(nc) || nc < 1L) 1L else nc; \
  options(Ncpus = nc, repos = c(CRAN = 'https://cloud.r-project.org')); \
  install.packages('https://cran.r-project.org/src/contrib/Archive/ggplot2/ggplot2_3.5.2.tar.gz', repos = NULL, type = 'source', dependencies = c('Depends', 'Imports', 'LinkingTo'), ask = FALSE, Ncpus = nc); \
  stopifnot(packageVersion('ggplot2') == '3.5.2')"

RUN R -e "options(repos = c(CRAN = 'https://cloud.r-project.org')); \
  install.packages('magick', type = 'source', ask = FALSE, Ncpus = 1L)"

# Bioconductor 核心（DE / SE / 注释 / GSVA / 热图 / Mart）；BiocManager 已在 bulkrna-base
RUN R -e "nc <- suppressWarnings(as.integer(Sys.getenv('R_INSTALL_NCPUS', '4'))); \
  nc <- if (is.na(nc) || nc < 1L) 1L else nc; \
  options(Ncpus = nc); \
  repos <- BiocManager::repositories(version = '3.20'); \
  repos['CRAN'] <- 'https://cloud.r-project.org'; \
  options(repos = repos); \
  BiocManager::install(c( \
    'SummarizedExperiment', 'AnnotationDbi', 'DESeq2', 'limma', \
    'GSEABase', 'GSVA', 'biomaRt', 'ComplexHeatmap', 'org.Hs.eg.db' \
  ), version = '3.20', ask = FALSE, update = FALSE, Ncpus = nc)"

RUN R -e "\
  suppressPackageStartupMessages({\
    library(SummarizedExperiment);\
    library(DESeq2);\
    library(limma);\
    library(GSVA);\
    library(GSEABase);\
    library(biomaRt);\
    library(ComplexHeatmap);\
    library(org.Hs.eg.db);\
  });\
  stopifnot(packageVersion('ggplot2') == '3.5.2');\
  cat('bulkRNA-Bioc-stage1 OK: DESeq2', as.character(packageVersion('DESeq2')), \
      ' GSVA', as.character(packageVersion('GSVA')), \
      ' ggplot2', as.character(packageVersion('ggplot2')), '\n')\
"

WORKDIR /work
