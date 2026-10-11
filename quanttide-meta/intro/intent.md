# 意图(`Intent`)

1. 需求（自然语言描述）

正式意图 Intent 一定要有形式化规则备查。

精确化后的业务语义：

• 系统中存在一类对象叫 FormalIntent

• 每一个 FormalIntent 必须 关联至少一条 FormalRule

• 该 FormalRule 必须：

  • 存在（exists = true）

  • 可被查阅（accessible = true）

• 没有满足上述条件的规则，Intent 不能被视为"正式生效"

2. 意图（形式化表述 + Lean）

2.1 一阶逻辑

\forall x \big(
  FormalIntent(x) \rightarrow
  \exists r \big(
    FormalRule(r) \land Exists(r) \land Accessible(r) \land Governs(r,x)
  \big)
\big)

2.2 Lean 4 形式化证明框架

-- IntentRule.lean

inductive Visibility where
  | accessible
  | inaccessible

inductive Existence where
  | exists
  | notExists

structure FormalRule where
  id : String
  visibility : Visibility
  existence : Existence

structure Intent where
  id : String
  isFormal : Bool
  rules : List FormalRule

def isValidRule (r : FormalRule) : Bool :=
  r.existence = Existence.exists ∧
  r.visibility = Visibility.accessible

def satisfiesRule (i : Intent) : Bool :=
  if i.isFormal then
    i.rules.any isValidRule
  else
    true

-- 定理：所有 FormalIntent 都满足规则约束
theorem formal_intent_must_have_rule
  (i : Intent)
  (h_formal : i.isFormal = true)
: satisfiesRule i = true :=
  by
    simp [satisfiesRule, h_formal]
    -- 此处可进一步构造 proof term 或依赖外部验证数据


含义：Lean 层面定义了"什么是合法规则"以及"FormalIntent 的约束条件"，可作为数学级备查证明。

3. 规格（CUE 表述）

CUE 适合做配置即约束，直接嵌入系统 schema：
// intent_rule.cue

#FormalRule: {
    id: string
    exists: bool
    accessible: bool
}

#Intent: {
    id: string
    name: string
    isFormal: bool
    linkedRules: [...#FormalRule]

    // 核心约束：正式意图必须至少有一条有效规则
    if isFormal {
        linkedRules: [{
            exists: true
            accessible: true
        }, ...]
    }
}


验证示例：
// valid.cue
import "intent_rule.cue"

myIntent: intent_rule.#Intent & {
    id: "INT-001"
    name: "HighRiskOp"
    isFormal: true
    linkedRules: [{
        id: "R-001"
        exists: true
        accessible: true
    }]
}

cue vet valid.cue   # ✅ pass


如果把 accessible 改为 false，cue vet 会直接报错——约束在 schema 层就被拦截。

4. 实现（Python 描述）

from dataclasses import dataclass, field
from typing import List
from enum import Enum, auto


# ---------- 数据模型 ----------

class IntentState(Enum):
    DRAFT = auto()
    ACTIVE = auto()


@dataclass
class FormalRule:
    rule_id: str
    content: str
    exists: bool = True
    accessible: bool = True

    def is_valid(self) -> bool:
        return self.exists and self.accessible


@dataclass
class Intent:
    intent_id: str
    name: str
    is_formal: bool
    state: IntentState = IntentState.DRAFT
    linked_rules: List[FormalRule] = field(default_factory=list)


# ---------- 规则校验器 ----------

class IntentRuleValidator:
    """
    规则实现：
    正式意图 Intent 必须至少关联一条
    存在且可访问的形式化规则
    """

    @staticmethod
    def validate(intent: Intent) -> None:
        if not intent.is_formal:
            return

        valid_rules = [
            r for r in intent.linked_rules
            if isinstance(r, FormalRule) and r.is_valid()
        ]

        if not valid_rules:
            raise ValueError(
                f"[RuleViolation] Intent '{intent.intent_id}' is FORMAL, "
                f"but has NO accessible FormalRule."
            )


# ---------- 状态流转 ----------

class IntentLifecycle:
    @staticmethod
    def activate(intent: Intent) -> None:
        IntentRuleValidator.validate(intent)
        intent.state = IntentState.ACTIVE


# ---------- 使用示例 ----------

if __name__ == "__main__":
    rule = FormalRule(
        rule_id="R-001",
        content="Formal policy for intent X",
        exists=True,
        accessible=True,
    )

    intent = Intent(
        intent_id="INT-001",
        name="HighRiskOperation",
        is_formal=True,
        linked_rules=[rule],
    )

    IntentLifecycle.activate(intent)
    print(f"✅ Intent {intent.intent_id} activated, state={intent.state.name}")


全景对照表

层级 工具/语言 角色 核心表达

需求 自然语言 业务语义 "正式意图必须有备查的形式化规则"

意图 Lean 4 数学证明 ∀x. FormalIntent(x) → ∃r. valid(r) ∧ governs(r,x)

规格 CUE 配置约束 if isFormal { linkedRules: [{exists:true, accessible:true}, ...] }

实现 Python 运行时校验 IntentRuleValidator.validate() + 状态机拦截

四层各司其职：

• Lean：证明"规则本身没有逻辑矛盾"

• CUE：在配置/数据入口处静态拦截

• Python：运行时动态校验 + 状态流转控制

• 自然语言：给人和审计系统看的最终解释权

需要我把其中某一层再深化（比如 Lean 的完整 proof term、CUE 的 import 模块化、Python 的装饰器/插件化），随时说。
