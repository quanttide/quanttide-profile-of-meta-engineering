// 议事与决议的规格（Cue 示例）。
// 示例代码，未运行。类型与不变量对应 index.md 概念与规格两节。
package delib

// 产生决议的三种机构
#Org: "company" | "alliance" | "trainingBase"

// 议题：议程上的条目
#AgendaItem: {
	id:       string
	summary:  string
	onAgenda: bool
}

// 草案：只挂一条议题，带提案国与版本
#Draft: {
	item: string                 // 挂在一条议题下
	text: int                    // 版本号，每次修订 +1
	sponsors: [...string]        // 提案国，可增可撤
	state: "submitted" | "onTable" | "passed" | "rejected"
}

// 决议：表决通过才发号，一号一命
#Resolution: {
	id: string
	item: string
	org: #Org
	phase: "pending" | "certified" | "published"
}

// C(r) 成立的相位：认证在场
#CertifiedPhase: "certified" | "published"

// inv1：标为社区决议的，相位必须已越过认证
#CommunityResolution: {
	id:    string
	item:  string
	org:   #Org
	phase: #CertifiedPhase
}

// inv2：相位是已发布的，认证必然在场（发布的前置就是 C）
#PublishedOnSite: {
	id:    string
	item:  string
	org:   #Org
	phase: "published"
}

// 实例：一条议题、一份草案、一份已发布的决议
agenda: [string]: #AgendaItem
agenda: "mid_east": {
	id:       "item-16"
	summary:  "中东局势（含巴勒斯坦问题）"
	onAgenda: true
}

drafts: [string]: #Draft
drafts: "pay_001": {
	item:       "item-16"
	text:       3
	sponsors:   ["alliance", "company"]
	state:      "passed"
}

resolutions: [string]: #Resolution
resolutions: "pay_001": {
	id:    "DELIB-0001"
	item:  "item-16"
	org:   "alliance"
	phase: "published"
}

// inv3：上桌的草案，其议题必在议程上——跨实体的对齐由工具核，
// Cue 侧的对应做法是把 agendaOn 提为草案字段的必填前提（此处示例从简）。
