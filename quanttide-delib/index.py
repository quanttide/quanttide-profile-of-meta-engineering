"""议事与决议的实现示例（Python）。

示例代码，未运行。每个动作各带前置检查，发布入口只放行满足 C(r) 的决议，
对应 index.md 概念、规格与实现三节。
"""

from dataclasses import dataclass
from enum import Enum

# 机构取值只认这三个，对着仓库里的主体名录
ORGS = ("company", "alliance", "trainingBase")


class DraftState(Enum):
    SUBMITTED = "submitted"
    ON_TABLE = "onTable"
    PASSED = "passed"
    REJECTED = "rejected"


class Phase(Enum):
    PENDING = "pending"        # 已通过、待认证——能成为决议，通过是前提
    CERTIFIED = "certified"
    PUBLISHED = "published"


@dataclass(frozen=True)
class AgendaItem:
    """议题：议程上的条目，有编号有摘要。"""

    id: str
    summary: str
    on_agenda: bool = True


@dataclass(frozen=True)
class Draft:
    """草案：只挂一条议题，带提案国与版本。"""

    item: str
    sponsors: tuple
    text: int = 1
    state: DraftState = DraftState.SUBMITTED


@dataclass(frozen=True)
class Resolution:
    """决议：表决通过才发号，一号一命。"""

    id: str
    item: str
    org: str
    phase: Phase = Phase.PENDING


def C(r: Resolution) -> bool:
    """社区决议的早期判定条件——认证在场。"""
    return r.phase in (Phase.CERTIFIED, Phase.PUBLISHED)


def review(a: AgendaItem, d: Draft) -> Draft:
    """上桌：pre 议题在议程上且有提案国（inv3 的闸门设在这里）。"""
    if not a.on_agenda:
        raise ValueError(f"议题 {a.id} 不在议程上，草案不进审议")
    if not d.sponsors:
        raise ValueError("草案没有提案国")
    return Draft(d.item, d.sponsors, d.text, DraftState.ON_TABLE)


def deliberate(d: Draft, res_id: str, org: str) -> tuple:
    """表决：pre 草案在桌；通过则发号产生决议（否决分支示例略）。"""
    if d.state is not DraftState.ON_TABLE:
        raise ValueError(f"议事前置不满足：草案相位 {d.state.value}")
    if org not in ORGS:
        raise ValueError(f"机构取值不合法：{org}")
    passed = Draft(d.item, d.sponsors, d.text, DraftState.PASSED)
    return passed, Resolution(res_id, d.item, org)


def certify(r: Resolution) -> Resolution:
    """创始人认证：pre 待认证。"""
    if r.org not in ORGS:
        raise ValueError(f"机构取值不合法：{r.org}")
    if r.phase is not Phase.PENDING:
        raise ValueError(f"认证前置不满足：当前相位 {r.phase.value}")
    return Resolution(r.id, r.item, r.org, Phase.CERTIFIED)


def publish(r: Resolution) -> Resolution:
    """官网发布：pre C(r)，inv2 的闸门设在这里。"""
    if not C(r):
        raise ValueError("官网只收满足 C(r) 的决议")
    return Resolution(r.id, r.item, r.org, Phase.PUBLISHED)
