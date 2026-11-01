# CHANGELOG

所有显著变更都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)。

版本遵循语义化版本规范：0.0.x（探索期）→ 0.x.y（验证期）→ x.y.z（正式期）。

---

## [Unreleased]

### 变更

- 新增 `quanttide-support/brochure.md`（对外口径）：一句定位、客户视角三步、客户能期待的两件事、保密边界；面向同行的售卖口径占位待立。对外材料不出现内部术语与机制
- `quanttide-support/index.md` 按两段分解为 `journal.md`（记录段：工单 → 工作日志 → 客户确认，落 `journal` 范畴，含一天一文件多张追加的写法、四格正常结局与五个任务单元）与 `profile.md`（加工整理段：日志 → 解决方案，落 `profile` 范畴，含适用条件、快照替换与旧版退位），供两仓 AGENTS 冷启动取用

### 新增

- `quanttide-support/index.md` 两段落位定死：记录段（原始回答 → 工作日志）落 `journal` 范畴，加工整理段（日志 → 解决方案）落 `profile` 范畴，子系统不自建容器
- `quanttide-support/index.md`《客户支持》：工单（问题侧）→ 工作日志（交客户确认）→ 解决方案（从日志提炼、带适用条件、旧版退位）两段分工，与日志仓的记录/加工整理同构；核心断言「办完 ⇔ 有一份经客户确认的日志」，超时、不回、转出均为正常结局；六个任务单元，规格、实现待补。经与创始人三轮岔路问答校验（工作日志与客户确认、解决方案带适用条件、未解决即关为正常结局）
- `quanttide-connect/communication-quality.md`：本地 AI 输出的沟通质量治理（需求 / 意图 / 规格 / 实现），出处 quanttide-connect 域日志 2026-10-19 及同日补记

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
