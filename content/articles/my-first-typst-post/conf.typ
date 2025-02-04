#let conf(
    me: none,
    doc) = {
  set page(
    paper: "a4",
    margin: (x: 1.8cm, y: 1.5cm),
  )

  set text(
      font: ("Microsoft YaHei","Times New Roman"),
      size: 15pt
  )

  show heading.where(level: 1): set text(size:30pt,weight: "bold")

  align(center)[
      = 每周汇报
      #datetime.today().display()  #me
  ]

  set align(left)
  doc
}