# CHANGELOG

所有显著变更都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)。

版本遵循语义化版本规范：0.0.x（探索期）→ 0.x.y（验证期）→ x.y.z（正式期）。

---

## [Unreleased]

## [0.1.0] - 2026-10-19

### 新增

- 仓库初始化：`README.md`、`CONTRIBUTING.md`、`LICENSE`（文档 CC BY / 代码 Apache 2.0）
- 迁入并整理按域分档的档案共 20 篇：
  - `quanttide-meta/` 7 篇：范畴（日志 vs 档案、档案 vs 案例集）、总览 `index.md`、`intro/intent.md`（意图：需求 / 意图 / 规格 / 实现四段）、本体（domain 2、entity 2、property 1）
  - `quanttide-delib/` 4 篇：议事规则的多语言形式化（`index.md` / `index.cue` / `index.lean` / `index.py`）
  - `quanttide-human/` 2 篇（招聘、人才质量标准）
  - `quanttide-agent/`、`quanttide-course/`、`quanttide-founder/`、`quanttide-github/`、`quanttide-media/`、`quanttide-relation/`、`quanttide-think/` 各 1 篇

### 变更

- 《量潮标准范畴》移出至案例集 `quanttide-gallery-of-meta-engineering`（移走不留副本）
- `quanttide-github/仓库初始化` 补充 License 约定（文档 CC BY、代码 Apache 2.0）与 submodule 规则、`gh create` 约束
