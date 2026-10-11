# GitHub仓库初始化

## 需求

我有一组git submodule创建规则，首先是创建领域第二大脑，比如 quanttide-search, 然后是根据规则创建仓库，比如quanttide-context/journal/xxx-of-search-engineering. 这里需要知道search和search-engineering; context、journal是一套固定规则。如果云端创建不加文件，比如README，子模块关联异常，所以gh create参数通常需要带README。默认是public，但是也可能有private的情况，所以要可以配置。补充：文档License是CC BY；代码License是Apache 2.0。
