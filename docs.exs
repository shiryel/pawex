alias RyushDiscord.{Guild, GuildTalk, GuildFlow, GuildEmojer}

[
  main: "readme",
  extras: [
    "README.md"
  ],
  source_url: "https://github.com/shiryel/pawex",
  nest_modules_by_prefix: [
    Pawex,
  ],
  groups_for_modules: [
    Main: [
      Pawex,
      Pawex.Tree
    ],
    Support: [
      Pawex.Tester
    ]
  ]
]
