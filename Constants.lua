local _, GreatVaultKeyInfo = ...

-- season data
GreatVaultKeyInfo.RaidItemLevels = {
    -- Midnight Season 2
    [120] = {
        [17] = 292, -- LFR
        [14] = 305, -- Normal
        [15] = 318, -- Heroic
        [16] = 334, -- Mythic
    },
}

-- this is from https://wago.tools/db2/MythicPlusSeasonRewardLevels?page=1&sort[WeeklyRewardLevel]=asc&filter[MythicPlusSeasonID]=120
GreatVaultKeyInfo.DungeonItemLevels = {
    -- Midnight Season 2
    [120] = {
        ["HEROIC"] = 289,
        ["MYTHIC"] = 302,
        [2] = 305,
        [3] = 305,
        [4] = 308,
        [5] = 308,
        [6] = 311,
        [7] = 315,
        [8] = 315,
        [9] = 315,
        [10] = 318,
    },
}

GreatVaultKeyInfo.WorldItemLevels = {
    -- Midnight Season 2
    [120] = {
        [1] = 279,
        [2] = 282,
        [3] = 285,
        [4] = 289,
        [5] = 292,
        [6] = 298,
        [7] = 302,
        [8] = 305,
    },
}

-- this is the minimum starting item level to go up a tier (the lowest values in the below table)
GreatVaultKeyInfo.ItemTierItemMinimumLevel = {
    -- Midnight Season 2
    [120] = {
        ["adventurer"] = 266,
        ["veteran"] = 279,
        ["champion"] = 292,
        ["hero"] = 305,
        ["myth"] = 318,
    },
}

-- ranks within each tier
GreatVaultKeyInfo.ItemTierItemLevels = {
    -- Midnight Season 2
    [120] = {
        ["adventurer"] = {
            [266] = 1,
            [269] = 2,
            [272] = 3,
            [276] = 4,
            [279] = 5,
            [282] = 6,
        },
        ["veteran"] = {
            [279] = 1,
            [282] = 2,
            [285] = 3,
            [289] = 4,
            [292] = 5,
            [295] = 6,
        },
        ["champion"] = {
            [292] = 1,
            [295] = 2,
            [298] = 3,
            [302] = 4,
            [305] = 5,
            [308] = 6,
        },
        ["hero"] = {
            [305] = 1,
            [308] = 2,
            [311] = 3,
            [315] = 4,
            [318] = 5,
            [321] = 6,
        },
        ["myth"] = {
            [318] = 1,
            [321] = 2,
            [324] = 3,
            [328] = 4,
            [331] = 5,
            [334] = 6,
            [337] = 7,
            [341] = 8,
            [344] = 9,
        },
    },
}

GreatVaultKeyInfo.ItemTierNumRanks = {
    -- Midnight Season 2
    [120] = {
        ["adventurer"] = 6,
        ["veteran"] = 6,
        ["champion"] = 6,
        ["hero"] = 6,
        ["myth"] = 9,
    },
}

GreatVaultKeyInfo.ExampleRaidRewardItemID = {
    -- Midnight Season 2
    --[120] = TODO,
}

-- the order of entries in this table matters, must be highest tier to lowest tier
GreatVaultKeyInfo.ItemTiers = {
    "myth",
    "hero",
    "champion",
    "veteran",
    "adventurer",
    --"explorer", we don't care about explorer because it can't be rewarded in the vault
}

-- fallback values
GreatVaultKeyInfo.WEEKLY_MAX_DUNGEON_THRESHOLD = 8
GreatVaultKeyInfo.WEEKLY_MAX_WORLD_THRESHOLD = 8
