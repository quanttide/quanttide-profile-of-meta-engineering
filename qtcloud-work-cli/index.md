# qtcloud-work CLI 一致性检查：用范畴论做形式化推理

平台自己写下过很多声明：规格页给的凭证公式、代码注释里的串法、「一次动作一份答复」的规矩、分层的规矩、「文件名即工作流名」、文件与文件之间的指认。每条声明在形式上都是一个隐含的等式或一张交换图——它声称「这样算和那样算得到同一个结果」「同一条路上的两条路通向同一个地方」「该唯一的东西只有一份」。这份档案做的事只有一件：把这些声明一条条写成显式的等式与图，代入真实代码与实跑值，报成立或不成立。

范畴论在这里是检查工具，不是修辞。对象与箭头用来把「同一件事的两种算法」写成一个等式；交换图用来把「两条路」画出来看交不交；唯一性条件（万能对象）用来把「该唯一」变成可判定的命题。凡是能形式化的才检查，检查不了的不写。

读者是产品经理，不需要会 Rust。每条检查同样四步：来源（哪句声明蕴含这条要求）、形式化（等式或图）、代入（标明「实跑」还是「读码」）、结论。全篇 13 条检查，成立 5 条、不成立 7 条、部分成立 1 条；总账在第八节，依赖图作为证据附在第九节。

分析对象是量潮工作云 CLI（crate `qtcloud-work-cli`，二进制 `qtcloud-work`），源码在 quanttide-work 仓 `apps/qtcloud-work/src/cli`，基线提交 `d6f63cc`，版本 0.1.0-beta.2；`src/` 51 文件 5137 行，42 个测试全绿，三条门禁全过——所以这 7 条不成立都不是 bug，测试覆盖的是行为，一致性断裂藏在行为之外。

## 一、怎么把平台摆成可检查的形式

范畴的一句话定义：把平台拆成一堆「对象」（名词，平台里真实存在的概念）和一堆「箭头」（从一个对象变出另一个对象的函数），箭头能首尾相接地接下去，叫复合。

```text
文件（YAML）──读入校验──→ 定义：工作流 ──→ 步骤 ──→ 判据
定义 ──补身份──→ 带身份的定义              定义 ──核对──→ 核对结论
工单 ←──开单时引一条定义──                工单 ──追加一笔──→ 工单（新）
工单 ──跑判据、AI 跑一步──→ 结果信封 ──发射──→ 屏幕 / 文件 / 退出码
定义与工单 ──发事件──→ 事件流（账本里的 JSONL，一行一条）
工作区（身份 + 落点）←──上面每个环节都来问路径与身份
```

三种检查模板，全篇复用：

1. 等式：同一件事两种算法，结果该逐位相等——不等就断（检查 1、2、3、8、10）。
2. 交换图：两条路该到同一个地方，或者表示该保持区分——交不上、塌在一起就断（检查 4、5、7）。
3. 唯一性与封闭：该唯一的只有一份、该覆盖的全覆盖、该扛住改动的配对扛得住——有例外、有反例就断（检查 6、9、11、12、13）。

## 二、身份的一致性（检查 1–3）

检查 1｜规格的凭证公式 = 实现的凭证公式？来源：规格页（workflow.md:18）与代码注释（ids.rs:16-17）、代码实现（ids.rs:28-31）对「这枚 id 怎么算」各写一版。等式：`uuid5(命名空间, 工作区id/名字) =? uuid5(命名空间, 工作区id/名字/workflow)`。代入（实跑，工作区 id `d169ce33-1daf-446b-a7e7-229bdd49a3b4`、名字 `demo`、命名空间 `90cf5627-95f3-5e25-ba48-47d50dee6e09`）：规格算得 `03a3ddd1-302e-50f1-ace5-d2e74b5777f4`，实现算得 `7976aabb-d5a9-577a-ae60-39baab92ed87`，而 `workflow show demo` 打出的正是后者。结论：不成立——本机自己用没事，任何另一端照规格页实现，两端算出的 id 不同，同一条工作流会被认成两条。哪一侧是本意由规格侧定，本档案只报告。

检查 2｜平台内三个落点的身份是否同一个值？来源：工单封面、事件负载、`workflow show` 都自称记的是这条工作流的身份。等式：`show 的 id = 工单的 workflow_id = 事件的 workflow_id`。代入（实跑）：三处都是 `7976aabb-d5a9-577a-ae60-39baab92ed87`；同一份定义连读两次都是 `fcea8686-d32a-5391-b741-444077643281`。结论：成立——本机内部自洽，读取确定且幂等。

检查 3｜「按名字派生、文件里不写 id」的声明与实现一致吗？来源：规格与注释都说身份按（工作区 id + 名字）现算，定义文件里一个 id 都不写。命题：改内容不换身份，换名字才换身份。代入（实跑）：把步骤「甲」改名「丙」后工作流 id 仍是 `49d51918-74b1-54f9-968f-9d8876a1ccc0`；同一份内容另存一名得 `d8b3357d-aaca-54c1-b770-906f5153956c`。结论：成立——定义可以自由编辑而身份不动；代价是名字成为唯一锚点，重名必须挡住（开单、导入都有重名挡）。

## 三、表示与重放的一致性（检查 4–6）

检查 4｜同一条定义的两种 JSON 相等吗？来源：平台把定义写两处——事件负载与 `workflow show --json` 的原文。等式：`事件里的定义 =? show 里的定义`。代入（实跑同一条 `demo`）：事件判据是 `{"executor":"rule","description":"存在：data/journal/README.md"}`，show 判据是 `{"executor":"rule","path":"data/journal/README.md"}`，事件还多出派生 id。结论：不成立——两条路各写各的，以后改判据字段要改两处，且现在已经不一致。

检查 5｜表示保持区分吗（两个不同的定义会不会塌成同一段）？命题：`d1 ≠ d2 ⇒ render(d1) ≠ render(d2)`。反例（实跑）：一条工作流的某步挂两个判据，只差文件名（`file: a.md` 与 `file: b.md`），说明都写「结论在」。同一条定义，show 的原文两条可分（`file` 字段各在），事件里则塌成一模一样的两段 `{"description":"结论在","executor":"rule"}`，`file` 没了。结论：不成立——事件这种表示不保信息，两个判据从此不可分。

检查 6｜事件流能重放盘上文件吗？来源：事件按设计是「只增不改、下游按 id 去重」的流水，暗含它可以还原事实。命题：`重放 events.jsonl = 当前盘上文件`。代入：工单侧（读码 + 实跑字段核对），`WorkOrderCreated` 带封面全部六字段、`WorkRecorded` 带记录全部八字段，逐事件重放即可拼回工单文件——成立；工作流侧，由检查 5 的反例，判据字段在写事件时已经丢掉，重放拼不回定义——不成立。结论：部分成立——两条流水，一条能回放一条不能。对产品的含义：想靠事件流做审计或对账的，工单可以指望，工作流指望不上。

## 四、变换与往返的一致性（检查 7–8）

检查 7｜展开占位与取说明文字，两条路交于同一处吗？命题（交换图）：`text(expand_r(c)) = replace_r(text(c))`——先把判据里的 `{{report}}` 换成真路径再取人话，与先取人话再替换，结果该同一串。代入（读码，实例来自 `tests/definition_check.rs:17` 真写的判据）：取 `PathExists{path:"{{report}}", description:""}`，两条路都得「存在：artifacts/report/单一.md」（落点与实跑 `order show` 打出的一致）。结论：成立——判据里的占位怎么算都一致。

检查 8｜写下去再读回来，还是原来那件吗？等式：`read(write(x)) = x`。代入（实跑）：工单追加两笔后 `order show` 读回的记录字段与写入逐项相同（含改名实验里那笔 `step: 甲` 原样）；定义读入后凭证重算仍是同一枚（检查 2 的 `fcea8686`）。结论：成立——账本与定义的落盘往返无损。

## 五、答复契约的一致性（检查 9）

检查 9｜19 条命令吃同一套 `--json` / `--out` / 退出码吗？来源：平台自己立的「一次动作一份答复」。用范畴论的话说，这是想给所有动作立一个万能对象——每条命令都得出一条、且只有一条箭头指到它（`Outcome`），由它统一打印、统一信封、统一落文件。命题：覆盖全体，无例外。代入（实跑，把 `--server` 指向拒绝连接的本地端口）：`--json health` 的 stdout 全空、stderr 一行「错误: 请求 … Connection refused」、退出码 1——没有 `ok`/`lines` 信封；`health --out X` 之后文件 X 根本没有被创建。读码佐证：`health` 自己打印、自己 `exit(1)`，全程不经过发射那一步。结论：不成立——19 分之 18，万能对象有一个洞；写跨命令解析器的脚本与 AI 要为 `health` 单开分支。

## 六、接头的一致性（检查 10–11）

工单不孤立，它靠两层配对挂在工作流上：外层是封面 `workflow_id` 对定义的 `id`，内层是每笔流水的步骤名与 `step_id` 对定义里的步骤。两条检查都在问同一件事——配对在平台允许的操作（改定义）下保不保持。

检查 10｜外层配对在改定义后保持吗？等式：`order.workflow_id = credentials(定义).id`，且改内容后两边同变或都不变。代入（实跑）：改步骤名前后，工单封面与定义算出的都是 `49d51918-74b1-54f9-968f-9d8876a1ccc0`——身份与内容无关（检查 3）保证了它。结论：成立。

检查 11｜内层配对在改定义后保持吗？命题：流水的 `step` / `step_id` 与定义的步骤随时对得上。代入（实跑的改名实验）：建两步工作流（甲、乙），开工单，人做完「甲」，此时「进度：1/2　下一步：乙」；把「甲」改名「丙」后同一条命令报「进度：0/2　下一步：丙」，那笔流水还在（`step: 甲`、`step_id: 7c42bd47-8bde-5d0d-b8c2-6262d62c0802`）却不再算数——进度按名对账，而 `step_id` 只被校验是 UUID 格式、不与工作流核对，名与 id 双存实际只用了名，改名后两样都成悬空引用。结论：不成立——配对只在写入瞬间成立，允许的改动会打破它，而系统不察、不报、不修。产品侧的观感就是：改一个步骤名，历史工单进度静默归零。

## 七、说明书与规矩的一致性（检查 12–13）

检查 12｜说明书描述的结构 = 实际结构吗？命题：分层表与落点图里的每个目录、路径，在 `src/` 里都存在。代入（读码）：

| 文档与位置 | 写的 | 现状 |
|:--|:--|:--|
| CONTRIBUTING.md:13 分层表 | 适配层列有 `locate/` | 目录不存在，并入了 `workspace/`（提交 `79d0204`） |
| CONTRIBUTING.md:33 依赖方向 | 「聚合之间的环已经不存在，workspace 一件也不引」 | 三个双向环都在（见附录模块邻接） |
| dev-guide/index.md:15、46、60 | 落点图与正文三处列 `locate/` | 同上 |
| criterion/model.rs:96 注释 | 落点见 `crate::task::execute` | 无此模块，实为 `order::execute` |
| tests/contract.rs 扫描清单 | 45 行文件名 | 三个文件各列两次 |
| Cargo.toml 依赖表 | `serde`（带 derive） | `src/` 一处未用 |

结论：不成立——说明书是模型的又一份表示，与实现不交换；照它走的新人会找错地方。

检查 13｜分层规矩 = 实际依赖吗？来源：CONTRIBUTING 第 31 行「服务可依赖聚合，聚合不得依赖服务」。命题：`src/` 里不存在聚合 → 服务的调用边。代入（读码）：`order/execute.rs:47-48` 与 `136-137` 四处调 `audit::run`（其中 `items_of` 只是 `criterion` 的再导出，真正跨层的是 `run`）；方向规矩里唯一有测试盯着的是「谁都不许依赖入口层」，这条没有。结论：不成立——规矩与图不一致，且没有执行机制，规矩本身成了第三份互不核对的表示。

## 八、总账

| # | 检查（形式化的声明） | 结果 |
|--:|:--|:--|
| 1 | 规格的凭证公式 = 实现的凭证公式 | 不成立 |
| 2 | show / 工单 / 事件三处身份同值，读取幂等 | 成立 |
| 3 | 身份按名键控、与内容无关的声明 | 成立 |
| 4 | 同一定义的两种 JSON 相等 | 不成立 |
| 5 | 表示保持区分（不塌缩） | 不成立 |
| 6 | 事件流可重放盘上文件 | 部分成立（工单可、工作流不可） |
| 7 | 展开与取话两条路交换 | 成立 |
| 8 | 写读往返无损 | 成立 |
| 9 | 19 条命令同一套答复契约 | 不成立（18/19） |
| 10 | 工单外层接头在改定义下保持 | 成立 |
| 11 | 工单内层接头在改定义下保持 | 不成立 |
| 12 | 说明书描述的结构 = 实际结构 | 不成立 |
| 13 | 分层规矩 = 实际依赖 | 不成立 |

七条不成立里有五条是同一个形状——同一件事写了两套算法或两份表示，彼此不核对（1、4、5、12、13）；剩下两条是键与通道选错（11 用名不用 id，9 有一个命令绕开信封）。而五条成立的全集中在「单一实现、纯计算」的地方（2、3、7、8、10）：凡是只有一份算法、不碰两份拷贝的，形式化检查全部通过；凡是有两个作者、两处落笔的，几乎全部断裂。这是这份检查给出的一致性画像，也是病根的定位——问题不在算法，在「同一个东西存了几份」。

三条要拍板的（拍了才能写成测试守着）：事件要不要保定义原文（检查 4、5、6）、`health` 要不要进信封（检查 9）、改步骤名后进度保不保（检查 11）。改动都落在 quanttide-work 仓，本档案只报告，不代改。

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

直接依赖六个 crate：clap 4.6.6（命令树）、serde_json 1.0.151（信封与事件）、serde_yaml 0.9.34（定义与账本读写）、ureq 2.12.1（只在 `health`）、uuid 1.26.1（v4 发号、v5 派生）、serde 1.0.229（零引用，见检查 12 的对账表）。进程边界四个：`pi`（`order/ai.rs:78`）、`sh -c`（`audit/mod.rs:51`）、`date`（`clock.rs:7`）、`git log`（`material/mod.rs:43`），外加 `health` 的一次 HTTP 请求。

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

方向性事实三条：入口层零被引（没有任何文件引 `crate::cli`，由 `tests/contract.rs` 的整目录扫描钉住）；`search → catalog` 单向成立；被引最广的是 workspace（16 个文件），其后 outcome（12）、criterion（8）、executor（7）、workflow（7）——检查 12、13 里的环与越线都汇在 workspace，与这份热度表一致。

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
         → ureq::get(<base>/health)；自己打印、自己 exit(1)，不进 emit（检查 9 的实况）
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
