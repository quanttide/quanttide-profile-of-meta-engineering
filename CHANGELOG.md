# CHANGELOG

所有显著变更都将记录在此文件中。

格式基于 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.0.0/)。

版本遵循语义化版本规范：0.0.x（探索期）→ 0.x.y（验证期）→ x.y.z（正式期）。

---

## [Unreleased]

### 变更

- `quanttide-consult/` 七份冷启动稿件已全部收录进领域仓 `quanttide-consult`：六资产仓（journal/profile/intention/insight/roadmap/brochure）AGENTS 全部就位并注册为子模块，领域仓 AGENTS 认知段在初始化时已写入；本仓源侧删除，不留副本（原文件由 git 历史取回）
- `quanttide-consult/` 创始人作为第一个客户入档（落死）：关系第一端放宽为「提出诉求的一方」，创始人同格不特例——档案照建、判据一视同仁不给特权、结算豁免打「内部关系」标签；「想得起我们」的落点第一次实测在创始人身上
- `quanttide-consult/` 落七份冷启动稿件：重点＝管理咨询关系（创始人给定，对标心理咨询，形态 lite/studio 入口，项目制不进本域）；落死两条判据（关系两端量潮↔企业、死活看客户有事想不想得起我们）；三条待定（「想得起」落点、lite/studio 分界、关系档案字段）；洞察三条候选带证伪条件、路线图站空待判据。领域仓未建，注入待建仓后


- `quanttide-agent/` 七份冷启动稿件已收录进领域仓 `quanttide-agent`：领域仓 AGENTS 认知段增核心循环（session → 找偏离 → 修 harness）与三级判据，其 journal/profile/intention/insight/roadmap/brochure 六子仓各自拿到 AGENTS（profile、roadmap 合并不覆盖存量规矩）；本仓源侧删除，不留副本（原文件由 git 历史取回），`pi-to-hermes.md` 不属本次搬运保留
- `quanttide-agent/` 未来三格补齐：新增 `insight.md`（判断可错、带证伪条件、不被意图收买，候选洞察「偏离成批出现」待 89 目录验证）与 `roadmap.md`（一步一格可验收、顺序由洞察撑着、两头对账）；`intention.md` 补「当验收标尺不参与论证」，`index.md` 落位与任务单元同步
- `quanttide-agent/` 新增 `intention.md`（未来·自我类）：本域要到哪去，创始人给定、不代配；意图只写方向不写路径指标，岔路问答校验，快照式替换
- `quanttide-agent/` 同任务形态的识别落定：不事前定义，事后指认——按工作目录机械筛、比对偏离描述，对得上才算同一个；规则适用场景绑偏离模式不绑目录，偏离字段写成「预期 X，实际 Y」的可比对形状
- `quanttide-agent/` 修正判据落死（岔路问答）：三级无终态——修订落地＝假设入档，不再偏＝暂时在位，再现偏离＝怀疑旧规则、证伪退位；「修好了」从本域拿掉，人写的规则本身不可信
- `quanttide-agent/` 冷启动稿件按创始人原话改写：重心不在挖掘知识经验，在「找 AI 偏离的细节 → 修 harness」——偏离是第二段唯一选料入口，落档记录增「偏离在哪」字段，产物为 harness 修正（loops/skills/prompts/agents 修订）；两条判据（修正判据、偏离粒度）待岔路问答
- `quanttide-agent/` 落四份冷启动稿件（`index.md` 总览、`journal.md` 记录段 session→落档、`profile.md` 加工整理段落档→提炼物、`brochure.md` 对外口径）：沿用 profile 仓现成提炼物组织（loops/skills/prompts/agents，按业务域），三条判据（办完、选料、结局格）待岔路问答落定，不先填

- `quanttide-support/` 三份冷启动稿件（`journal.md`、`profile.md`、`brochure.md`）已收录进领域仓 `quanttide-support`：领域仓 `AGENTS.md` 认知段改写，其 `data/journal`、`data/profile`、`data/brochure` 三子仓各自拿到 `AGENTS.md`；本仓源侧删除，不留副本（原文件由 git 历史取回）
- `CONTRIBUTING.md` 新增「跨仓搬运」节：冷启动稿件收录前是正本不能删、收录后源侧删除不留副本，留痕靠 CHANGELOG 与 git 历史
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

- `quanttide-consult/` 七份冷启动稿件已全部收录进领域仓 `quanttide-consult`：六资产仓（journal/profile/intention/insight/roadmap/brochure）AGENTS 全部就位并注册为子模块，领域仓 AGENTS 认知段在初始化时已写入；本仓源侧删除，不留副本（原文件由 git 历史取回）
- `quanttide-consult/` 创始人作为第一个客户入档（落死）：关系第一端放宽为「提出诉求的一方」，创始人同格不特例——档案照建、判据一视同仁不给特权、结算豁免打「内部关系」标签；「想得起我们」的落点第一次实测在创始人身上
- `quanttide-consult/` 落七份冷启动稿件：重点＝管理咨询关系（创始人给定，对标心理咨询，形态 lite/studio 入口，项目制不进本域）；落死两条判据（关系两端量潮↔企业、死活看客户有事想不想得起我们）；三条待定（「想得起」落点、lite/studio 分界、关系档案字段）；洞察三条候选带证伪条件、路线图站空待判据。领域仓未建，注入待建仓后


- `quanttide-agent/` 七份冷启动稿件已收录进领域仓 `quanttide-agent`：领域仓 AGENTS 认知段增核心循环（session → 找偏离 → 修 harness）与三级判据，其 journal/profile/intention/insight/roadmap/brochure 六子仓各自拿到 AGENTS（profile、roadmap 合并不覆盖存量规矩）；本仓源侧删除，不留副本（原文件由 git 历史取回），`pi-to-hermes.md` 不属本次搬运保留
- `quanttide-agent/` 未来三格补齐：新增 `insight.md`（判断可错、带证伪条件、不被意图收买，候选洞察「偏离成批出现」待 89 目录验证）与 `roadmap.md`（一步一格可验收、顺序由洞察撑着、两头对账）；`intention.md` 补「当验收标尺不参与论证」，`index.md` 落位与任务单元同步
- `quanttide-agent/` 新增 `intention.md`（未来·自我类）：本域要到哪去，创始人给定、不代配；意图只写方向不写路径指标，岔路问答校验，快照式替换
- `quanttide-agent/` 同任务形态的识别落定：不事前定义，事后指认——按工作目录机械筛、比对偏离描述，对得上才算同一个；规则适用场景绑偏离模式不绑目录，偏离字段写成「预期 X，实际 Y」的可比对形状
- `quanttide-agent/` 修正判据落死（岔路问答）：三级无终态——修订落地＝假设入档，不再偏＝暂时在位，再现偏离＝怀疑旧规则、证伪退位；「修好了」从本域拿掉，人写的规则本身不可信
- `quanttide-agent/` 冷启动稿件按创始人原话改写：重心不在挖掘知识经验，在「找 AI 偏离的细节 → 修 harness」——偏离是第二段唯一选料入口，落档记录增「偏离在哪」字段，产物为 harness 修正（loops/skills/prompts/agents 修订）；两条判据（修正判据、偏离粒度）待岔路问答
- `quanttide-agent/` 落四份冷启动稿件（`index.md` 总览、`journal.md` 记录段 session→落档、`profile.md` 加工整理段落档→提炼物、`brochure.md` 对外口径）：沿用 profile 仓现成提炼物组织（loops/skills/prompts/agents，按业务域），三条判据（办完、选料、结局格）待岔路问答落定，不先填

- 《量潮标准范畴》移出至案例集 `quanttide-gallery-of-meta-engineering`（移走不留副本）
- `quanttide-github/仓库初始化` 补充 License 约定（文档 CC BY、代码 Apache 2.0）与 submodule 规则、`gh create` 约束
