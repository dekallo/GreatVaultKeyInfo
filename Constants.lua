local _, GreatVaultKeyInfo = ...

-- season data
GreatVaultKeyInfo.RaidItemLevels = {
    -- Midnight Season 1
    [117] = {
        [17] = 233, -- LFR
        [14] = 246, -- Normal
        [15] = 259, -- Heroic
        [16] = 272, -- Mythic
    },
}

-- this is from https://wago.tools/db2/MythicPlusSeasonRewardLevels?page=1&sort[WeeklyRewardLevel]=asc&filter[MythicPlusSeasonID]=117
GreatVaultKeyInfo.DungeonItemLevels = {
    -- Midnight Season 1
    [117] = {
        ["HEROIC"] = 243,
        ["MYTHIC"] = 256,
        [2] = 259,
        [3] = 259,
        [4] = 263,
        [5] = 263,
        [6] = 266,
        [7] = 269,
        [8] = 269,
        [9] = 269,
        [10] = 272,
    },
}

GreatVaultKeyInfo.WorldItemLevels = {
    -- Midnight Season 1
    [117] = {
        [1] = 233,
        [2] = 237,
        [3] = 240,
        [4] = 243,
        [5] = 246,
        [6] = 253,
        [7] = 256,
        [8] = 259,
    },
}

-- this is the minimum starting item level to go up a tier (the lowest values in the below table)
GreatVaultKeyInfo.ItemTierItemMinimumLevel = {
    -- Midnight Season 1
    [117] = {
        ["adventurer"] = 220,
        ["veteran"] = 233,
        ["champion"] = 246,
        ["hero"] = 259,
        ["myth"] = 272,
    },
}

-- ranks within each tier
GreatVaultKeyInfo.ItemTierItemLevels = {
    -- Midnight Season 1
    [117] = {
        ["adventurer"] = {
            [220] = 1,
            [224] = 2,
            [227] = 3,
            [230] = 4,
            [233] = 5,
            [237] = 6,
        },
        ["veteran"] = {
            [233] = 1,
            [237] = 2,
            [240] = 3,
            [243] = 4,
            [246] = 5,
            [250] = 6,
        },
        ["champion"] = {
            [246] = 1,
            [250] = 2,
            [253] = 3,
            [256] = 4,
            [259] = 5,
            [263] = 6,
        },
        ["hero"] = {
            [259] = 1,
            [263] = 2,
            [266] = 3,
            [269] = 4,
            [272] = 5,
            [276] = 6,
        },
        ["myth"] = {
            [272] = 1,
            [276] = 2,
            [279] = 3,
            [282] = 4,
            [285] = 5,
            [289] = 6,
        },
    },
}

GreatVaultKeyInfo.ItemTierNumRanks = {
    -- Midnight Season 1
    [117] = {
        ["adventurer"] = 6,
        ["veteran"] = 6,
        ["champion"] = 6,
        ["hero"] = 6,
        ["myth"] = 6,
    },
}

GreatVaultKeyInfo.ExampleRaidRewardItemID = {
    -- Midnight Season 1
    [117] = 249336, -- Signet of the Starved Beast
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
