# qtcloud-work CLI 建模问题：范畴论分析

这份档案写给产品经理：不需要会 Rust，也不需要读过源码。每个范畴词第一次出现都用一句话说清它是什么，随后摆一条代码实况，最后说它暴露了平台建模的什么问题。证据分两种并在文中标明——「实跑」是临时工作区真跑出来的值，「读码」是从源码直接读出的结论。

分析对象是量潮工作云 CLI（crate `qtcloud-work-cli`，二进制 `qtcloud-work`），源码在 quanttide-work 仓 `apps/qtcloud-work/src/cli`，基线提交 `d6f63cc`，版本 0.1.0-beta.2。`src/` 51 个文件 5137 行，42 个测试全绿，格式、严格 lint 与单文件行数三条门禁全过。也就是说，这是在一份「门禁全绿」的代码上找建模问题，不是找 bug：测试保证每条命令的行为对，建模问题问的是另一件事——同一个概念在平台里被定义成了几份、有几条互相打架的路、图上哪里不该回头却回了。

结论五条，正文第二到第六节逐条给证据；第七节是同一张图上健康的部分，第八节是可以变成验收的等式，第九节把依赖图作为证据附上。

1. 身份：同一枚凭证，规格、注释、代码三处定义算出三个值（第二节）。
2. 表示：同一件东西有两条不一致的 JSON，还有一条命令绕开统一答复（第三节）。
3. 箭头重复：路径显示、取字段这类小概念各有两三个实现（第四节）。
4. 环：工作区一个概念顶两顶帽子，全仓的环汇在它身上，分层规矩写了没有钉子（第五节）。
5. 约定滞后：结构重构后，给人看的说明书没跟上（第六节）。

## 一、平台摆成一张图

范畴的一句话定义：把平台拆成一堆「对象」（名词，平台里真实存在的概念）和一堆「箭头」（从一个对象变出另一个对象的函数），箭头能首尾相接地接下去，叫复合。

对象就是这些概念，源码里各有其名：定义侧是工作流、步骤、判据（`Workflow` / `Step` / `Criterion`）；账本侧是工单、工作记录、事件（`WorkOrder` / `WorkRecord` / 事件流的一行）；答复侧是结果信封（`Outcome`）、目录（`Catalog`）、材料（`Material`）；身份是凭证（UUID 字符串）。场所侧要单独点名：它其实是两个对象——`Workspace` 是工作区的身份（这台机器上这个工作区是谁），`LocalWorkspace` 是落点（根、账本、工作流目录、产物各在哪）。第五节的问题正出在这两个对象被焊在一起。

箭头按方向分四组，各举真实的：

1. 文件 → 概念（读入）：`validate` 先判这份 YAML 合不合法，`Workflow::of` / `WorkOrder::of` 再读成内存里的对象。
2. 概念 → 文件或 JSON（写出）：`WorkOrder::to_yaml` 落盘、`events::yaml_to_json` 装事件、`Outcome::to_json` 封信封。
3. 概念 → 概念（内部变换）：`Workflow::credentials` 补身份、`Criterion::expanded` 换占位、`progress::*` 由流水推进度。
4. 概念 → 答复 → 屏幕（对外）：十八个动作把任何概念装进 `Outcome`，`emit` 打印并给退出码；`health` 是例外，见第三节。

```text
文件（YAML）──读入校验──→ 定义：工作流 ──→ 步骤 ──→ 判据
定义 ──补凭证──→ 带身份的定义          定义 ──核对──→ 核对结论
工单 ←──开单时引一条定义──            工单 ──追加一笔──→ 工单（新）
工单 ──跑判据、AI 跑一步──→ 结果信封 ──emit──→ 屏幕 / 文件 / 退出码
定义与工单 ──发事件──→ 事件流（账本里的 JSONL，一行一条）
工作区（身份 + 落点）←──上面每个环节都来问路径与身份
```

下面五个问题，都是这张图上的三种病：一个对象被定义成了几份（第二、四节），该重合的两条路没重合（第三节），图上汇了不该汇的环（第五节）；第六节是图与说明书脱节。

## 二、身份：同一枚凭证，三处定义算出三个值

身份的一句话定义：平台用 UUID 回答「这一个东西是谁」——工作流、步骤、工单、流水各一枚，跨机器、跨时间对账全靠它。所以「这枚 id 怎么算出来」是平台最应该只有一份的定义。

实跑：拿同一个工作区 id `d169ce33-1daf-446b-a7e7-229bdd49a3b4`、名字 `demo`、钉死的命名空间 `90cf5627-95f3-5e25-ba48-47d50dee6e09`，三处文字各给出一种串法：

| 来源 | 串法 | uuid5 算出的值 |
|:--|:--|:--|
| 规格页（workflow.md:18） | `工作区id/工作流名` | `03a3ddd1-302e-50f1-ace5-d2e74b5777f4` |
| 代码注释（ids.rs:16-17） | `工作区id/workflow/工作流名` | `8478d7a7-231c-50b4-902f-dd97ac575e8e` |
| 代码实现（ids.rs:28-31） | `工作区id/工作流名/workflow` | `7976aabb-d5a9-577a-ae60-39baab92ed87` |

第三行是实跑 `workflow show demo` 打出的 id，工单封面与事件负载里也是它；前两行是规格页与注释各自写的串法，都算不出它。哪一处是本意，由规格侧定，本档案只报告——但对产品的含义是明确的：将来任何一端（服务端、另一个工具）照规格页去实现，两端算出的 id 就不同，同一条工作流会被认成两条。

第二件事，实跑的改名实验，它是身份问题的另一半：

1. 题目：建一条两步工作流（甲、乙），开工单，人做完「甲」，然后把工作流里的「甲」改名成「丙」。
2. 各处实际返回：改名前 `order show` 报「进度：1/2　下一步：乙」；改名后报「进度：0/2　下一步：丙」，流水里那笔记录还在（`step: 甲`、`step_id: 7c42bd47-8bde-5d0d-b8c2-6262d62c0802`），但不再算走过。
3. 白话：进度是拿流水里的步骤名去对定义里的步骤名算出来的，名字一改就对不上；账上那枚 id 也没人用来对账——校验只检查它是 UUID 格式，不与工作流核对。名与 id 双存，实际只用了名。

建模问题：平台的「身份」在规格、注释、代码三处各有一份定义，只有代码那份在生效；流水里同时存名与 id，身份体系只建了一半。产品侧看到的现象是：改一个步骤名，历史工单的进度会静默归零，之前做完的不再算数，且没有任何提示。

## 三、表示：同一件东西两条不一致的 JSON，还有一条命令绕开统一答复

交换图的一句话定义：从同一件东西出发去同一个目的地，走两条路本该得到同一个结果；画成方框，两边结果相等叫交换，不等就是建模上的「同一件事有两个真相」。

第一个方框不交换，实跑同一条 `demo` 定义，两种 JSON 摆在一起：

```text
事件 WorkflowCreated 里的 criteria     → [{"executor": "rule", "description": "存在：data/journal/README.md"}]
workflow show --json 的 payload.criteria → [{"executor": "rule", "path": "data/journal/README.md"}]
```

左路是写事件时手搓的 JSON，判据的 `path` 字段被折进一句描述，还补了派生 id；右路是把 YAML 原样搬进 JSON，字段齐全但没有 id。两条路从同一个定义出发，落点不同——以后要改判据字段，得同时改两处，而且现在已经不一致。

第二个方框里有一条路根本不进图：平台自己立的规矩是「一次动作一份答复」，十八个动作都产出 `Outcome`，经 `emit` 打印、按 `--json` 出同一套信封、按 `--out` 落文件、退出码 0 或 1。`health` 不走这条通道。实跑（指向一个拒绝连接的本地端口）：`--json health` 的 stdout 全空，stderr 一行「错误: 请求 … Connection refused」，退出码 1——没有 `ok`/`lines` 那层信封；带 `--out` 时目标文件根本没有被创建，这个选项对 `health` 无效。

第三处分叉是读码：写动作的「预演」（`--dry-run`）在两个分派文件里各写一份，九处手写分支、九句手写文案（工作流三条、工单五条、审计一条），预演不是动作自带的属性，而是复制在各处的判断。新增一条命令时漏掉哪一处，预演就缺哪一条，没有东西会提醒。

建模问题：答复通道有一个例外，定义的表示有两套，预演有九份拷贝。平台把 AI 与脚本定位成第一等调用方，而对它们来说这三处都意味着同一个风险——每加一条命令，都可能再漏掉一处一致性。

## 四、箭头重复：同一个小概念，仓里有两三把尺子

一句话定义：两个函数吃同样的输入、本该给同样的输出，它们就是本该重合成一条的箭头；重合不了，说明概念没收敛，改动会漏。

- 路径显示短一点：`workspace::short`（local.rs:214，按字符串剥前缀）与 `catalog::short`（catalog/mod.rs:84，按路径组件剥）。读码可证的差异：路径正好等于根时，前者给原样，后者给空串。
- 取一个字符串字段：`fields::text_of`、`workflow/yaml::text_of`、`order/model::text_of` 三份实现，语义相同（都取值、去空白、缺了当空）。
- 工作流内容转 JSON：两条，已在第三节实跑。

建模问题：三组重复就是三处改动点，改一处不会有任何人提醒另一处。平台目前还没有把「显示路径」「读字段」这类小概念收成一处，这正是第二个问题（一个概念几份定义）在小零件上的重演。

## 五、环：工作区这一个概念顶着两顶帽子

环的一句话定义：A 认识 B、B 也认识 A，图上就成环。环本身不是病，病在环里那条「不该回头的边」没有测试看着。

读码的结果，`src/` 里有三个双向环：工作区 ⇄ 工单、工作区 ⇄ 事件、工单 ⇄ 话术（给 AI 的提示词）；外加一个三元环，工作区 → 工单 → 工作流 → 工作区。多数环里有一条只传类型不跑逻辑（编译器不查、运行时不走），拆起来容易；唯一两侧都是真调用的是工作区 ⇄ 事件——事件落盘要先问工作区身份，工作区开账又要先发一个事件，它靠「先把身份文件写盘、再发第一个事件」这个顺序终止，顺序一动就无限递归，而这个顺序没有测试钉住。

越线一处（读码）：工单执行调用了审计服务四次，而 CONTRIBUTING 写明「服务可依赖聚合，聚合不得依赖服务」；这一条同样没有测试，唯一有测试盯着的方向规矩是「谁都不许依赖入口层」。

白话：「工作区」同时是业务概念（一次工作的边界）和物理概念（文件落哪、账本开哪），所以每个环节都要认识它——全仓 16 个文件引它，所有环都汇在这一个点上。分层的规矩是写了的，但只有「谁都不许依赖入口层」这一条有测试兜底；规矩要生效，得先变成能跑的东西。

## 六、约定滞后：结构变了，说明书没跟上

| 文档与位置 | 写的 | 现状（读码） |
|:--|:--|:--|
| CONTRIBUTING.md:13 分层表 | 适配层列有 `locate/` | 目录已不存在，并入了 `workspace/`（提交 `79d0204`） |
| CONTRIBUTING.md:33 依赖方向 | 「聚合之间的环已经不存在，workspace 一件也不引」 | `workspace/local.rs` 引工单与资产表，上一节三个环都在 |
| dev-guide/index.md:15、46、60 | 落点图与正文三处列 `locate/` | 同上，图滞后于两次重构 |
| criterion/model.rs:96 注释 | 落点见 `crate::task::execute` | 仓里没有 `task` 模块，实为 `order::execute` |
| tests/contract.rs 扫描清单 | 45 行文件名 | 三个文件各列了两次 |
| Cargo.toml 依赖表 | `serde`（带 derive 特性） | `src/` 一处也没用 |

白话：新人和产品经理看的那份「结构说明」——分层表、落点图——描述的是重构前的世界。这与第三节、第四节是同一种病在文档层的重演：同一个结构存了几份，其中几份已经死了，而没有任何机制发现它们死了。

## 七、同一张图上健康的部分

体检也得报健康项，下面三处的建模是干净的，理由与前面五个问题正好相反。

- 状态只有一份真相：进度、完结、待拍板都不落字段，随时由「定义 + 流水」重算。改定义不会留下过期的状态副本——这正是第二节那种「几份定义打架」的反面。
- 占位展开是一次守规矩的变换。函子的一句话定义：把一个映射套进容器里，先套再套结果一样。`Criterion::expanded` 满足它的两条律——不换占位时等于没换（恒等），两次展开等于合成一条 resolve 再展开一次（复合）（读码）。
- 命令树是穷尽的。余积的一句话定义：一个变体一个分支，合起来覆盖全部。19 条叶子命令由 `cli::run` 一个 match 全覆盖，没有兜底分支——以后加命令忘了写处理，编译期就报错，等不到运行。
- 错误出口只有一个形状（除 `health`）：实跑三条错误路径——查无此单、查无此流、查无此步——退出码都是 1，报错都是「哪一句断了说哪一句」。

## 八、可以变成验收的三个等式

范畴论在这份档案里的用处，最后落到能被检查的等式上。当前状态：

1. 凭证等式「规格串 = 代码串」：不成立，三串实测只有代码串命中实际值。哪一侧是本意，由规格侧定。
2. 展开等式「先展开后取话 = 先取话后替换」：成立，靠代码自洽，没有测试守着。
3. 答复等式「19 条命令同一套 `--json` / `--out` / 退出码」：有一个例外，`health`。

外加一个要产品拍板的行为：改工作流步骤名之后，历史工单的进度是保住还是重置。现状是静默重置（第二节实跑），是缺陷还是设计，得产品定——定了它，才谈得上把它写成测试。

改动都落在 quanttide-work 仓，本档案只报告，不代改。

## 九、证据：依赖图

### 分层与规模

按物理目录统计（`events.rs` 与 `workspace/local.rs` 在 CONTRIBUTING 里算适配件，物理上一个在根、一个在 `workspace/` 目录里，本表按位置归）：

| 落位 | 文件 | 行数 | 占比 |
|:--|--:|--:|--:|
| 聚合目录（order / workflow / workspace / material / catalog / artifact） | 26 | 3119 | 61% |
| 根下中立件（criterion / error / outcome / fields / paths / ids / executor / clock / sha1 / events） | 13 | 943 | 18% |
| 领域服务（search / audit） | 2 | 222 | 4% |
| 适配与入口（main / cli.rs / cli/ / help / prompts / health） | 10 | 853 | 17% |
| 合计 | 51 | 5137 | 100% |

直接依赖六个 crate：clap 4.6.6（命令树）、serde_json 1.0.151（信封与事件）、serde_yaml 0.9.34（定义与账本读写）、ureq 2.12.1（只在 `health`）、uuid 1.26.1（v4 发号、v5 派生）、serde 1.0.229（零引用，见第六节）。进程边界四个：`pi`（`order/ai.rs:78`）、`sh -c`（`audit/mod.rs:51`）、`date`（`clock.rs:7`）、`git log`（`material/mod.rs:43`），外加 `health` 的一次 HTTP 请求。

### 模块邻接

「调」表示有函数调用，「型」表示只传类型（字段、参数、返回值）。只列 `src/` 内真实引用，文档注释里提到但代码没引的不算。

```text
main.rs              → cli                                        调
cli.rs               → cli/{commands,emit,handlers}               子件
cli/emit             → catalog（write_json）outcome               调
cli/handlers/command → order 七个动作、workflow open + 六个动作
                       workspace（resolve / short）outcome         调
cli/handlers/workspace → artifact audit catalog health help material
                         search workspace::local::root outcome     调
help                 → outcome                                    调
prompts              → criterion                                  调
                     → order（WorkRecord，只作参数类型）           型
health               → （仓内零依赖）
events               → clock（now）workspace（LocalWorkspace 两个方法） 调
order/actions        → workflow open、order/{events,model}、workspace、executor、outcome 调
order/ai             → prompts 四个函数                            调
                     → criterion、paths、workflow、workspace        调/型
order/events         → events{append,yaml_to_json}、order/model、workspace 调/型
order/execute        → audit{items_of,run}                         调
                     → order{Order,ai}、criterion、ids、workflow    调/型
order/inspect        → order/{progress,journal,listing,open}、outcome、workspace、events 调/型
order/journal        → workspace（artifact_path）                   调
order/mod            → workspace::local::write_yaml                 调
                     → workflow、workspace、ids、clock              调/型
order/progress       → workflow                                     调/型
order/record         → ids                                          调
workflow/actions     → workflow/{check,events,mod}、outcome、workspace 调/型
workflow/check       → criterion、paths（placeholders_in）、workflow 调/型
workflow/events      → events（append）、workflow、workspace        调/型
workflow/model       → criterion、executor、ids（derive）           调/型
workflow/mod         → executor、workspace、本聚合子件              调/型
workflow/read        → criterion、error、executor、fields           调/型
workflow/yaml        → workflow::validate                           调
workspace/events     → events（append）、workspace                 调/型
workspace/local      → order（WorkOrder，只作参数类型）             型
                     → artifact（named/place）、sha1（sha1_hex）    调
                     → workspace/{events,model}                     调
workspace/model      → clock、ids                                   调
catalog              → artifact（assets/locate）、outcome           调
material             → outcome                                      调
audit                → catalog、artifact、outcome、workspace        调
                     → criterion（经再导出的 items_of）             调
search               → catalog、outcome、workspace                  调
criterion/items      → criterion/model                               调
criterion/model      → executor、paths（replace_placeholders）       调/型
criterion/read       → error、executor、fields、paths                调/型
error                → executor、fields、paths                       调/型
artifact/model       → criterion（Criterion，字段类型）              型
outcome fields paths executor ids clock sha1 → （只到 std / serde_* / uuid）
```

方向性事实三条：入口层零被引（没有任何文件引 `crate::cli`，由 `tests/contract.rs` 的整目录扫描钉住）；`search → catalog` 单向成立；被引最广的是 workspace（16 个文件），其后 outcome（12）、criterion（8）、executor（7）、workflow（7）。

### 命令级调用链

入口与装载，所有命令共用：

```text
入口   main::main → cli::run_from_env（cli.rs:63）→ Cli::parse（clap 派生）
                    → cli::run（cli.rs:68）→ handlers::<命令>
装载   handlers::command::locate（command.rs:8）→ LocalWorkspace::resolve（local.rs:48）
       根   --root > $QTCLOUD_WORK_ROOT > repo_root（向上找含 data/journal 的目录）
       账   --data > account → workspace_key → sha1::sha1_hex（工作区键 = 目录名 + 8 位短码）
       产物 --artifacts > <根>/artifacts      工作流 --workflows > <账>/workflows
```

工作流六条：

```text
create   locate → [dry-run 则报出将写的路径] → workflow_create（workflow/actions.rs:11）
         → create（workflow/mod.rs:98）：check_flows_dir → WorkflowFile::new → write（建目录、写 YAML）
         → flow.credentialed → workspace_id → ensure（缺身份：Workspace::new → write_yaml → workspace::events::created）
         → workflow::events::created → events::append → 回落 workflow_show → emit
show     locate → workflow_show（actions.rs:35）→ open（mod.rs:169）→ WorkflowFile::new().reload → yaml::load（读文件 + validate）
         → 不存在则 lines(false)；存在则 credentialed → Workflow::credentials → ids::derive（工作流 1 枚、每步 1 枚）
         → Outcome{columns, rows, data{payload, workflow_id, step_ids}} → emit
list     locate → workflow_list（actions.rs:96）→ listing（mod.rs:223：read_dir + 排序 + 逐个 open）→ emit
check    locate → workflow_check（actions.rs:122）→ open → check::check（check.rs:23）
         逐 step × rule 取字面量（占位跳过）→ inside（check.rs:89）核路径在区内
         → sections（check.rs:106）取描述小节对 contains 覆盖 → all_ok / describe → emit
export   locate → workflow_export（actions.rs:166）→ open → export（fs::write 原样带走）→ emit
import   locate → workflow_import（actions.rs:184）→ import：check_flows_dir → yaml::load（先 validate）
         → 重名挡 → 改写 name 字段 → write → events::created → emit
```

工单七条：

```text
create   locate → [先 workflow::open 验存在，再 dry-run] → order_create（order/actions.rs:10）
         → create（order/mod.rs:167）：重名挡 → open 工作流 → credentialed
         → WorkOrder{id: ids::new_id, workflow_id, created_at: clock::now} → record::validate
         → Order::save（mod.rs:45）→ workspace::local::write_yaml（local.rs:235）
         → order::events::created → append → 回落 order_show → emit
show     locate → order_show（order/inspect.rs:20）→ open（order/mod.rs:103）
         → 读文件 + serde_yaml → record::validate_yaml（字段表 + 流水纪律）→ workflow_by_id（mod.rs:120）
         → Order{locate, payload, workflow} → progress::{done_steps, next_step, state_line, pending_gates}
         → Outcome.data{payload, workflow, artifacts} → emit
list     locate → order_list（inspect.rs:86）→ listing（mod.rs:129，逐个 open、按工作流名过滤）
         → progress::finished → emit
next     locate → [dry-run] → order_next（actions.rs:37）→ open → progress::next_step
         步骤是 human 则只提示「人做的不替你做」；否则 execute::walk（execute.rs:19）
         → 无闸门且 AI 跑通则 order.append（mod.rs:63）→ events::recorded → 重 open 取 state_line → emit
done     locate → [dry-run] → order_done（actions.rs:72）→ open → workflow.step
         → execute::record_by_human（execute.rs:130，只跑 rule 判据）→ order.append → events::recorded → emit
journal  locate → [dry-run] → order_journal（actions.rs:114）→ open → journal::narrate（journal.rs:12，读-滤-写）
         → artifact_path → artifact::place::place（<类别>/<工单名>.md）→ emit
delete   locate → [dry-run] → order_delete（actions.rs:140）→ delete（mod.rs:205）
         → open → 流水非空即拒 → fs::remove_file → Outcome.data{name} → emit
```

工作区四条与发射：

```text
search   handlers::search → local::root → search::search（search/mod.rs:36）
         → catalog::build → matches（search/mod.rs:12，先精确后互相包含）→ Outcome.with_first → emit
catalog  handlers::catalog → local::root → catalog::catalog（catalog/mod.rs:196）
         → build：artifact::assets × artifact::locate × documents/title_of/cn_name → emit
audit    handlers::audit → local::root；dry-run 走 artifact::missing 列预告
         → audit::audit（audit/mod.rs:96）→ artifact::{make,missing} + catalog::build.unregistered → emit
material handlers::material → local::root → material::material（material/mod.rs:187）
         → materials → as_material → first_seen（git log 退回文件名日期）+ stage_of → emit
help     handlers::help → help::topic（help.rs:52）或 help::guide（help.rs:70）→ emit
health   handlers::health → health::resolve_base（health.rs:9）→ health::health（health.rs:21）
         → ureq::get(<base>/health)；自己打印、自己 exit(1)，不进 emit（见第三节）
发射     emit（cli/emit.rs:8）
         --out  → catalog::write_json(out, to_output_json)（原文那一栏，没有则整个信封）
         --json → envelope_json（emit.rs:33，data 的键抬到顶层留一轮）→ 打印
         默认   → 打 lines；ok=false 时 stderr 补一句「下一步」
         退出码 → result.ok ? 0 : 1（emit.rs:26）
```

三条跨聚合的公共链：

```text
事件   <聚合>::events::{created,recorded} → events::append（events.rs:12）
       → locate.workspace_id → ensure：身份缺则 Workspace::new（ids::new_id + clock::now）
         → write_yaml → workspace::events::created
         ↑ 这里会再进一次 append，靠「身份先写盘、再发事件」终止（local.rs:111-127）
       → 补 event / at / workspace_id 三个公共字段 → events_file 追加一行 JSONL
判据   ai::expanded_criteria（order/ai.rs:69）→ Criterion::expanded（criterion/model.rs:97）
       → paths::replace_placeholders（paths.rs:24）→ audit::items_of（实为 criterion 再导出）
       → audit::run（audit/mod.rs:76）→ audit::check（:26）：
         PathExists / PathAbsent 走 fs exists，FileContains 读文件比对，CommandRun 起 sh -c，None 归 pending
AI     ai::prompt_for → facts_of（order/ai.rs:19）+ expanded_criteria → prompts::prompt_for（prompts.rs:38）
       ai::run_ai（order/ai.rs:77）→ Command::new("pi").args(["-p", "--no-session", prompt]).current_dir(root)
       ai::judge_by_ai（:132）→ judge_prompt → run_ai → verdict_of（:105，认「序号. 通过 / 不通过」那行）
```

### 结构体依赖

27 个 struct 与 enum 全列，「字段」是静态持有，「→」是方法里的调用：

| 结构体 | 所在 | 字段与方法引到 |
|:--|:--|:--|
| `Cli` | cli.rs:28 | 字段 `command: Command`；只被 `cli` 与两个 handler 读 |
| `Command` / `WorkflowCommand` / OrderCommand | cli/commands.rs | 无仓内依赖，纯参数树；叶子命令共 19 个（顶层 6 + workflow 6 + order 7） |
| `Outcome` | outcome.rs:12 | 字段 `data: Option<serde_json::Value>`；`new` / `lines` / `with_first` / `to_json` / `to_output_json` |
| `LocalWorkspace` | workspace/local.rs:35 | `order_file`（:97）收 `&WorkOrder`（型）；`workspace_id` → `ensure` → `Workspace` 与 `workspace::events::created`；`artifact_path` → `Artifact::named` + `place` |
| `Workspace` | workspace/model.rs:15 | `new` → `ids::new_id` + `clock::now`；`parse` / `to_mapping` |
| `WorkOrder` | order/model.rs:21 | 字段 `records: Vec<WorkRecord>`；`of` / `to_yaml`；字段表 `FIELDS` 六项 |
| `WorkRecord` | order/model.rs:74 | `of` / `to_yaml`，无仓内依赖 |
| `Order` | order/mod.rs:33 | 三字段即三件：`locate` + `payload` + `workflow`；`save` → `write_yaml`；`append` → `record::append_check` + `workflow.step` + `clock::now` + `record::validate` |
| `WorkflowFile` | workflow/mod.rs:38 | `locate: LocalWorkspace` + `payload: Value`；`credentialed` → `workspace_id` + `Workflow::credentials`；`reload` → `yaml::load` |
| `Workflow` | workflow/model.rs:51 | 字段 `steps: Vec<Step>`；`credentials` → `ids::derive` |
| `Step` | workflow/model.rs:14 | 字段 `criteria: Vec<Criterion>`；`rules` / `agents` / `gates` 按 executor 过滤 |
| `Criterion` | criterion/model.rs:26 | 六变体；`executor` / `description` / `text` / `expanded` → `paths::replace_placeholders` |
| `RuleKind` / `RuleItem` | criterion/model.rs:14、items.rs:11 | `RuleItem{description, kind, args}`；`machine()` 决定跑不跑 |
| `Position` / `Fault` / `DefinitionError` | error.rs:12、36、141 | `Fault.text` 的文案取 `executor` / `fields` / `paths` 三张常量表 |
| `Finding` | workflow/check.rs:16 | 三字段；由 `check::check` 造，`describe` / `all_ok` 消 |
| `Asset` | artifact/mod.rs:45 | 无字段依赖；`assets()` = `STATED` 11 格 + `PROCEDURAL` 9 格 |
| `Artifact` | artifact/model.rs:12 | 字段 `spec: Vec<Criterion>`；`named()` |
| `Catalog` / `Entry` | catalog/mod.rs:29、23 | `PathBuf` + `BTreeSet`；`unregistered` → `artifact::assets` / `locate` |
| `Material` | material/mod.rs:13 | 无依赖；`missing()` 查四字段 |
| `Facts` | prompts.rs:23 | 十个 `String` 字段；`facts_of` 拼，`prompt_for` / `judge_prompt` 消 |
| `WorkflowError` | workflow/yaml.rs:10 | `String` newtype，包 `validate` 的报错文字 |
