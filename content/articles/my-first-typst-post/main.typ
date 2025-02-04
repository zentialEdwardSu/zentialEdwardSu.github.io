#set page(
    paper: "a4",
    margin: (x: 1.8cm, y: 1.5cm),
  )

#set text(
      font: ("Microsoft YaHei","Times New Roman"),
      size: 12pt
)

#show table.cell.where(y: 0): strong
#set table(
  stroke: (x, y) => if y == 0 {
    (bottom: 0.7pt + black)
  },
  align: (x, y) => (
    if x > 0 { center }
    else { left }
  )
)

#set math.equation(numbering: "(1)",block: true)
#show math.equation.where(block: true): set align(center)
#show math.equation.where(block: true): set text(font: "New Computer Modern Math",size: 18pt)


// #show heading.where(level: 1): set text(size:30pt,weight: "bold")
#set align(left)

= System Model v2

符号表
#table(
  columns: 2,
  align: (center,center),
  table.header(
    [Symbol],[Meaning]
  ),
  [$theta_(a,b)$],
)

== Overview

#let ub = " 基站 <= 用户"
#let ur = " RIS <= 用户"
#let rb = " 基站 <= RIS"

Assumption:
+ 系统由三个成员组成，基站，RIS天线，用户，其中：
  - 基站 使用 ULA 排布的天线；
  - RIS 使用 UPA 排版的天线；
  - 用户为单用户
+ 考虑上行链路，信道概况：
  - 基站 <= RIS: 远场的MIMO信道
  - RIS <= 用户: 近场的SIMO信道(NUSW)
  - 基站 <= 用户: 远场的SIMO信道

从最基本的满足我们所设定场景与假设的模型出发，如@modelv1 所示

#figure(
  image("images/systemall.png",width: 80%),
  caption: [The overall system model]
)<modelv1>

由于本文的目标是 UE=>RIS=>BS 的信道建立与追踪，按照 @swindlehurstChannelEstimationReconfigurable2022 Sec.IV的总览最后一段所述，为了简化讨论，可假设不存在#ub 的信道$H_d$，此时总系统模型如 @modelv2 所示。

以下将分别对#ur 信道与 #rb 信道详细解释。

#figure(
  image("images/system_model.png",height: 30%),
  caption: [Simplified System Model]
)<modelv2>


== #rb 信道

与 @huangRoadsideIRSAidedVehicular2023 相似，从ULA阵列的响应矩阵(Steering Vector)开始，并使用函数形式描述，如@esv。其中：
+ $dash(M)$是一个方向上天线的总数，
+ $phi$ 是归一化到$pi$的邻近天线相位差

$
e(phi,dash(M) ) = [1, e^(j pi phi),...,e^(j (dash(M) - 1) pi phi)]^T 
$<esv>

在我们的模型中，依照@esv 可列出BS ULA阵列天线与RIS UPA阵列天线的响应矩阵。



#bibliography("ref.bib",title: "Reference")

