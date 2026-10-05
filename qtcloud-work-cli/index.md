# qtcloud-work CLI 依赖图与范畴论分析

对象是 quanttide-work 仓 `apps/qtcloud-work/src/cli` 的源码：crate `qtcloud-work-cli`，二进制 `qtcloud-work`，版本 0.1.0-beta.2，edition 2024，基线提交 `d6f63cc`（工作区干净）。`src/` 51 个文件 5137 行，`tests/` 17 个文件 1601 行，42 个测试，`cargo test --locked` 全绿。

方法：逐文件读完 `src/`，用 `grep crate::` 拉引用边，并剔除文档注释里的提法——注释与约定文档里还有指向已不存在路径的引用（`crate::task::execute`、`locate/`，见「约定文档对账」）；再在临时工作区真跑一遍二进制，调用链与输出都以实跑结果为准，实测值附在对应小节。

第一部分是依赖图，从模块到结构体到函数；第二部分把同一张图摆成范畴论的说法，每个说法都落回具体签名与实测值，跑不了的给到文件行。

## 一、依赖图

### 分层与规模

按物理目录统计（`events.rs` 与 `workspace/local.rs` 在 CONTRIBUTING 里算适配件，物理上一个在根、一个在 `workspace/` 目录里，本表按位置归）：

| 落位 | 文件 | 行数 | 占比 |
|:--|--:|--:|--:|
| 聚合目录（order / workflow / workspace / material / catalog / artifact） | 26 | 3119 | 61% |
| 根下中立件（criterion / error / outcome / fields / paths / ids / executor / clock / sha1 / events） | 13 | 943 | 18% |
| 领域服务（search / audit） | 2 | 222 | 4% |
| 适配与入口（main / cli.rs / cli/ / help / prompts / health） | 10 | 853 | 17% |
| 合计 | 51 | 5137 | 100% |

体量最大的四件：`workspace/local.rs` 241、`material/mod.rs` 240、`workflow/mod.rs` 238、`order/mod.rs` 216，都贴着 250 行红线（`scripts/validate-line-count.sh` 门槛）。聚合内部 order 十件 1216 行、workflow 七件 912 行。

直接依赖六个 crate：clap 4.6.6（命令树）、serde_json 1.0.151（信封与事件）、serde_yaml 0.9.34（定义与账本读写）、ureq 2.12.1（只在 `health`）、uuid 1.26.1（v4 发号、v5 派生）、serde 1.0.229——最后这个在 `src/` 里一次也没被引用：没有 `use serde`，没有 `Serialize`/`Deserialize`，只是依赖表里挂着。

进程边界四个：`pi`（`order/ai.rs:78`，把一步交给 AI）、`sh -c`（`audit/mod.rs:51`，跑 `run` 判据）、`date`（`clock.rs:7`，取时刻）、`git log`（`material/mod.rs:43`，取文件首次入库日期）；外加 `health` 的一次 HTTP GET。

### 模块邻接

「调」表示有函数调用，「型」表示只引类型（字段、参数、返回值）。只列 `src/` 内真实引用，文档注释里提到但代码没引的不算。

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

三条方向性事实：入口层零被引，`src/` 下没有任何文件引 `crate::cli`，这一条由 `tests/contract.rs` 的「动作层不依赖入口层」整目录扫描钉住；`search → catalog` 单向写在 `search/mod.rs:3` 的注释里并成立；被引最广的是 workspace（16 个文件），其次 outcome（12）、criterion（8）、executor（7）、workflow（7）。

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
         步骤是 human 则只提示「人做的不替你做」；否则 execute::walk（execute.rs:19），详见下方 AI 链与判据链
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
         → ureq::get(<base>/health)；失败 eprintln + std::process::exit(1)
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
| `Command` / `WorkflowCommand` / `OrderCommand` | cli/commands.rs | 无仓内依赖，纯参数树；叶子命令共 19 个（顶层 6 + workflow 6 + order 7） |
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

### 环与越线

双向环三个。`workspace ⇄ order`：型边是 `workspace/local.rs:97` 的 `order_file(&WorkOrder)`，调用边是 `Order::save` → `write_yaml` 等六个文件；`workspace ⇄ events`：两侧都是真调用（`append` → `workspace_id`，`workspace::events::created` → `append`）；`order ⇄ prompts`：调用边是 `order/ai` 引 `prompts` 四个函数，型边是 `previous_records` 收 `&[WorkRecord]`。另有一个三元环 `workspace → order → workflow → workspace`，首条是型边。

运行时真正会来回走的只有 `workspace ⇄ events` 一条：`ensure` 写完 `workspace.yaml` 才发 `WorkspaceCreated`，嵌套那次进来时身份已在，不再下钻（`local.rs:111-127`）。其余环里型边过编译器、不过运行时。

越线一处：`order/execute.rs:47-48` 与 `136-137` 调 `crate::audit`，而 CONTRIBUTING 第 31 行写「服务可依赖聚合，聚合不得依赖服务」。其中 `audit::items_of` 只是 `criterion::items_of` 的再导出（`audit/mod.rs:23`），真正跨层的只有 `audit::run`；这一条没有测试钉住，contract.rs 只钉入口层方向。

### 约定文档对账

| 文档与位置 | 写的 | 现状 |
|:--|:--|:--|
| CONTRIBUTING.md:13 适配层 | 列有 `locate/` | 目录不存在，已并入 `workspace/`（提交 `79d0204`） |
| CONTRIBUTING.md:31 依赖单向 | 「服务可依赖聚合，聚合不得依赖服务」 | `order/execute.rs` 调 `audit::run` 四处，无测试钉住 |
| CONTRIBUTING.md:33 依赖单向 | 「聚合之间的环已经不存在……workspace 一件也不引」 | `workspace/local.rs` 引 `order` 与 `artifact`，上节三个双向环都在 |
| docs/dev-guide/index.md:15、46、60 | 落点图与正文三处列 `locate/` | 同上，落点图滞后于 `4457a2e`、`79d0204` 两次重构 |
| criterion/model.rs:96 注释 | 落点见 `crate::task::execute` | 仓里没有 `task` 模块，落点实为 `order::execute` |
| ids.rs:16-17 注释 | 串「上级凭证/类别/名字」 | 代码是参数后追加类别，即「上级凭证/名字/类别」（ids.rs:28-31） |
| quanttide-work docs/specification/process/workflow.md:18 | `uuid5(命名空间, "<工作区 id>/<工作流名>")` | 代码多一段类别，公式与实现对不上 |
| Cargo.toml 依赖表 | `serde = { version = "1", features = ["derive"] }` | `src/` 无一处引用 |
| tests/contract.rs 入口层扫描清单 | 45 行文件名 | `workspace/{events,mod,model}.rs` 各列两次 |

凭证那一条可以实测：同一工作区 id `d169ce33-1daf-446b-a7e7-229bdd49a3b4`、名字 `demo`，命名空间 `90cf5627-95f3-5e25-ba48-47d50dee6e09`：

| 来源 | 串法 | uuid5 结果 |
|:--|:--|:--|
| 规格 workflow.md:18 | `工作区id/工作流名` | `03a3ddd1-302e-50f1-ace5-d2e74b5777f4` |
| ids.rs 注释 | `工作区id/workflow/工作流名` | `8478d7a7-231c-50b4-902f-dd97ac575e8e` |
| 代码 ids.rs:28-31 | `工作区id/工作流名/workflow` | `7976aabb-d5a9-577a-ae60-39baab92ed87` |

第三行就是实跑 `workflow show demo` 打出的 id——规格与注释两串都算不出它。步骤那层同理：规格串 `工作流id/甲` 算得 `b9950d55-…`，代码串 `工作流id/甲/step` 算得 `ae320ca3-8d49-5179-86e7-c9a5ae2e954b`，与事件负载里的 `step_id` 一致。此处只报告，改规格还是改代码由规格仓定。

## 二、范畴论分析

### 读法

范畴论在这里只用六个词：对象、态射、复合、单位、积与余积、拉回。对象就是类型，态射就是有名字有签名的函数，复合就是把一个的返回喂给下一个，单位就是原样返回的那条。下面每小节先给这个小节那个词的一句话定义，再摆真实签名，能跑的给实测值，跑不了的给文件行；没有代码落点的说法不写。

### 对象与态射

对象是上一部分那 27 个 struct 与 enum，外加 `order/execute.rs:13` 的元组别名 `type Judging = (String, String, String)` 与单元 `()`。态射按方向分五组，签名全是真的：

```text
YAML → 领域    validate: (&Yaml) -> Result<(), DefinitionError>   workflow/read.rs:54
               Workflow::of: (&Yaml) -> Workflow                  workflow/read.rs:39
               Step::of: (&Yaml) -> Step                          workflow/read.rs:17
               criterion_of: (&Yaml) -> Criterion                 criterion/read.rs:15
               WorkOrder::of: (&Yaml) -> WorkOrder                order/model.rs
领域 → YAML    WorkOrder::to_yaml                                 order/model.rs
               Workspace::to_mapping                              workspace/model.rs
领域 → JSON    events::yaml_to_json: (&Yaml) -> Json              events.rs:40
               Outcome::to_json / to_output_json                  outcome.rs
               workflow::events::to_json: (&Workflow) -> Json     workflow/events.rs
领域 → 领域    Workflow::credentials(self, &str) -> Workflow       workflow/model.rs:62
               Criterion::expanded<F>(self, F) -> Criterion        criterion/model.rs:97
               items_of: &[Criterion] -> Vec<RuleItem>            criterion/items.rs:24
               progress::{done_steps, next_step, finished}        order/progress.rs
领域 → Outcome 十八个动作函数：workflow 六个、order 七个、
               catalog / audit / search / material / help::guide
Outcome → 输出 emit: (Outcome, &Cli) -> i32                       cli/emit.rs:8
```

复合就是相邻两个函数的类型对得上。真实一条，从磁盘到退出码：

```text
handlers::search(&str, bool, &Cli)
  → local::root(Option<&Path>) -> PathBuf                 根
  → search::search(&Path, &str, bool) -> Outcome          建索引：内部走 catalog::build → artifact::locate
  → Outcome::with_first(String) -> Outcome                添一行「工作区：…」
  → emit(Outcome, &Cli) -> i32                            打印
  → std::process::exit(i32)                               main.rs:27
```

单位的例子两个，都可验证：`paths::replace_placeholders` 在 resolve 全部返回 `None` 时把字符串原样拼回，连 `{{` 都不带地提前返回（`paths.rs:28`）——不换占位等于没换；`LocalWorkspace::resolve` 四处位置全给了值时逐处照收（`local.rs:48-72`），装载等于没装载。这两个「等于没做」在范畴里就是单位态射。

### 积与余积

积的定义：几个对象拼成一件，取字段就是投影。`Order` 是标准件——`open()`（`order/mod.rs:103`）与 `create()`（:167）都在末尾拼 `Order{locate, payload, workflow}`，`.locate` / `.payload` / `.workflow` 三个访问就是投影，三样缺一这个积就合不起来，所以「工单打不开」的报错也分三种。`Facts` 是十个字符串的积，由 `facts_of`（`order/ai.rs:19`）一次拼装、`prompt_for` / `judge_prompt` 整体消费。

余积的定义：几个对象并成一族，`match` 一个分支一个对象，合起来必须穷尽。仓里五处大的余积：`Command` 八个变体（叶子 19 条命令）由 `cli::run`（`cli.rs:68`）一个 match 消成 `i32`；`Criterion` 六个变体由 `Criterion::executor`（`criterion/model.rs:54`）与 `audit::check`（`audit/mod.rs:26`）两处分别消去；`Fault` 十八个变体由 `Fault::text` 消成一句人话；`Position` 三个变体由 `phrase` 消成话头；`RuleKind` 四个变体由 `audit::check` 消成四种跑法。

单元 `()` 是终点对象：`ensure()`、`validate()` 都返回 `Result<(), String>`，不产内容，只说成不成。空枚举（初始对象）仓里没用到。

白话一句：命令进来是余积的消去，结果出去是积的投影，中间所有函数都是这两件事的组合。

### 单子与失败管道

`Result<T, String>` 的定义：一条可能失败的管道件，每步返回 `Result`，`?` 接力，错误串原样往上冒，哪步断了就停在哪步。这是仓里最厚的一条链，`order::open` 四步接力：读文件、`serde_yaml` 解析、`record::validate_yaml` 校验、`workflow_by_id` 找所引工作流，任何一步 `Err` 都直接返回调用方。

实跑三条错误路径，退出码都是 1：

```text
order show 查无此单   → 没有这件工单：/tmp/…/workorders/查无此单.yaml
workflow show 查无此流 → 没有这条工作流：.xdg/…/workflows/查无此流.yaml
order done 单一 不存在的步骤 → 所引工作流里没有这一步：不存在的步骤
```

断点各在 `open` 的第一段、`workflow::open` 的 `exists` 检查、`order_done` 的 `workflow.step` 查找——三个不同的位置，同一种形状：动作函数拿到 `Err` 的第一件事是 `Outcome::lines(false, vec![error])`，把管道失败翻译成答复。

`Option → Result` 是一族对得齐的箭头（自然变换）：`workflow_by_id` 返回 `Option<Workflow>`，`order/mod.rs:111` 用 `.ok_or_else(|| format!("这单引的工作流不见了（workflow_id={}）", …))` 把它统一抬成 `Err`，`order/mod.rs:74` 对 `workflow.step` 做同一件事。消去处在每个动作开头的 `match … Err(error) => return Outcome::lines(false, …)`。

### 函子与自然变换

函子的定义：把一个映射套进容器里，先套再套结果一样。仓里三个现成容器都只用到 `map` 这一面：`Vec::map`（`workflow/actions.rs` 收步骤名、`audit/mod.rs:76-84` 造逐条结果）、`Option::map`（`order/inspect.rs` 里 `fresh.map(|order| order.state_line()).unwrap_or_default()`）、`Result::map_err`（`workspace/model.rs:48` 包装身份解析错误）。

真正带结构的是 `Criterion::expanded`。它的参数是一条 resolve：`&str → Option<String>`，即「占位名换成哪条路径」；把这类 resolve 按「先 `r1`、`r1` 的产物再过 `r2`」接起来就是复合，全返回 `None` 的那条是单位，于是 resolve 自己构成一个小范畴，`expanded` 把每条 resolve 送成 `Criterion` 上的一个自同态：

- 恒等律成立：resolve 全返回 `None` 时 `replace_placeholders` 原样返回，展开等于没展开。
- 复合律成立：按上述接法合成一条 resolve，一次展开等于依次两次展开，因为接法本身就定义成「`r1` 的产物再过 `r2`」。

实值例（判据取自 `tests/definition_check.rs:17` 与 `tests/defaults.rs:85` 真写的 `file: '{{report}}'`）：resolve 把 `report` 换成 `artifacts/report/单一.md`（由 `place_of` → `LocalWorkspace::artifact_path` → `artifact::place::place` 算出，与实跑 `order show 单一` 打出的 `artifacts/report/单一.md` 一致），展开后的 `Criterion` 就是把 `{{report}}` 换成这条路径的那一条。

自然变换的定义：一族箭头横着对得齐——两条不同走法，终点相同。这里有一条真的：

```text
Criterion  ──text()──→  String
   │ expanded(r)             │ replace_placeholders(r)
   ▼                         ▼
Criterion  ──text()──→  String
```

取 `Criterion::PathExists{path: "{{report}}", description: ""}`：往上走再往右，`text()` 空说明走格式分支得「存在：{{report}}」，再替换得「存在：artifacts/report/单一.md」；先往右再往下，替换后是 `PathExists{path: "artifacts/report/单一.md"}`，`text()` 得同一串。两条路都过，因为 `expanded` 对说明与路径一视同仁地套同一次替换（`criterion/model.rs:97-135`），而 `text()` 只是从这两个字段拼话（:78-91）。

### 三张交换图

第一张交换，凭证派生。同一个 `Workflow` 对象，两条路：读定义后走 `Workflow::credentials` 现算 id，或不读定义直接拿 `(工作区 id, 名字)` 喂 `ids::derive`。实测两路交于 `7976aabb-d5a9-577a-ae60-39baab92ed87`——与 `workflow show`、工单封面、事件负载三处看到的完全一致。上一节的表同时说明：规格与注释各自描述的那条路都交不到这个点。

第二张不交换，工作流内容 → JSON 有两条路，结果不同。实测同一条 `demo` 定义：

```text
事件 WorkflowCreated 的 criteria    → [{"executor": "rule", "description": "存在：data/journal/README.md"}]
workflow show --json 的 payload.criteria → [{"executor": "rule", "path": "data/journal/README.md"}]
```

左路是 `workflow::events::to_json` 手搓，判据字段被折进 `description`，还补了派生 id；右路是 `serde_json::to_value(&flow.payload)` 原样搬 YAML，保字段但没有 id。两者从同一个内容出发却不同构——改判据字段时，一处只动左路、一处只动右路，谁也不会提醒谁。

第三张交换，`--json` 信封。`emit` 的两个分支从同一个 `Outcome` 取：`--json` 走 `to_json`（四样信封），`--out` 走 `to_output_json`（`data` 原文），同源显然交换。实跑 `catalog --json` 还能看到兼容层：`count` 同时出现在顶层与 `data` 内——`envelope_json`（`emit.rs:33`）把 `data` 的键抬到顶层留一轮，是故意加宽的一次不交换，注释写明「只加不改，下一轮删」。

### 极限与余极限

拉回的定义：两支箭头指向同一个键，把两边键相同的对象配成一对。仓里两处真拉回。

工单打开是 `WorkOrder --workflow_id--> WorkflowId ←--id-- Workflow` 的拉回，配对处是 `workflow_by_id`（`order/mod.rs:120`）：遍历区内定义、逐条现算凭证、认 id 相等的那条；配不齐就 `Err("这单引的工作流不见了")`。进度判定是 `records --step--> 步骤名 ←--name-- steps` 的拉回，`progress::done`（`order/progress.rs:68`）拿名字对名字，配上且 `is_succeeded` 为真即算走过。值得注意的是账上另存了一枚 `step_id`，`record::validate_records` 只验它是 UUID（`order/record.rs:90`），不与工作流对接——真正接头用的是名字。

积就是上一节的 `Order`。余极限就是 `Command` 那棵 19 个叶子的树，`cli::run` 的 match 把它整体消成一位退出码；`Outcome → {0, 1}`（`emit.rs:26`）与 `health` 失败时直接 `exit(1)`，是同一个塌缩的两处出口。

事件侧是一个幺半群同态：`events.jsonl` 是「行」的自由幺半群，`events::append` 先拼一行再追加，连拼两次等于一次拼接，内容与顺序都不改。规范要求 `WorkspaceCreated` 必须是第一行，实跑首行正是它——这条规范等于指定了一条全局截面。

### 白话总成绩

把整张图摆成范畴论，买到三件能直接用的事。

第一，同一对类型之间出现两个函数，就是「箭头不唯一」，改一处必漏另一处。仓里现在有三组：`short` 两个（`workspace/local.rs:214` 按字符串剥前缀，`catalog/mod.rs:84` 按路径组件剥，`path == root` 时一个给原样一个给空串）、`text_of` 三个（`fields.rs`、`workflow/yaml.rs`、`order/model.rs` 各一份，语义相同）、工作流内容转 JSON 两条（事件手搓 vs `show` 原样，已经不一致）。

第二，环不可怕，要分清哪条是型边。四个环里三条含型边——`order_file(&WorkOrder)` 与 `previous_records(&[WorkRecord])` 两处把类型缝在一起，编译器不查、运行时不走；把这两处换成路径或 id 参数，环当场散架。唯一两条真调用边构成的环是 `workspace ⇄ events`，靠「先写身份再发事件」的写盘顺序终止，这个终止条件没有测试钉住，动 `ensure` 顺序就会递归。

第三，交换图可以直接落成测试。凭证那张已有实测值（规格、注释、代码三串只有一串命中实际值）；`text ∘ expanded = replace ∘ text` 那张现在只靠代码自洽；事件与 `show` 那张已知不交换，是有意的两种口径还是漏改，得由规格侧定。三张里已知的偏差都在上面「约定文档对账」一节，本档案只报告，不代改。
